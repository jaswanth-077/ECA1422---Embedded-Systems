#include <systemc.h>
#include <algorithm>
#include <iomanip>
#include <iostream>
#include <queue>
#include <string>
#include <vector>
#include <cmath>

// ECA1422 SystemC discrete-event scheduler model.
// The model uses the same task parameters as the technical report.
// Time unit: milliseconds. Priority: larger number = higher priority.

struct TaskDef {
    std::string name;
    int priority;
    double wcet_ms;
    double period_ms;
    double deadline_ms;
};

struct Job {
    int id;
    int task_index;
    double release_ms;
    double deadline_ms;
    double remaining_ms;
};

struct ReadyCompare {
    const std::vector<TaskDef>* tasks;
    bool operator()(const Job& a, const Job& b) const {
        int pa = (*tasks)[a.task_index].priority;
        int pb = (*tasks)[b.task_index].priority;
        if (pa != pb) return pa < pb;
        if (a.release_ms != b.release_ms) return a.release_ms > b.release_ms;
        return a.id > b.id;
    }
};

SC_MODULE(ECA1422Scheduler) {
    std::vector<TaskDef> tasks;
    std::priority_queue<Job, std::vector<Job>, ReadyCompare> ready;
    int next_job_id = 0;
    int deadline_misses = 0;
    double busy_ms = 0.0;

    SC_CTOR(ECA1422Scheduler) {
        tasks = {
            {"SensorTask",  5, 0.18,   1.0,    1.0},
            {"FeatureTask", 4, 1.80,  20.0,   20.0},
            {"AITask",      3, 4.50, 100.0,  100.0},
            {"CommTask",    2, 8.00, 500.0,  500.0},
            {"HealthTask",  1, 0.70,1000.0, 1000.0}
        };
        ready = std::priority_queue<Job, std::vector<Job>, ReadyCompare>(ReadyCompare{&tasks});
        SC_THREAD(run);
    }

    void release_jobs(double now_ms, double horizon_ms) {
        for (size_t i = 0; i < tasks.size(); ++i) {
            const auto& t = tasks[i];
            // Release at 0, T, 2T, ... strictly before the simulation horizon.
            double k = std::floor(now_ms / t.period_ms + 1e-9);
            double release = k * t.period_ms;
            if (release < horizon_ms - 1e-9 && std::fabs(release - now_ms) < 1e-9) {
                ready.push(Job{next_job_id++, static_cast<int>(i), release,
                               release + t.deadline_ms, t.wcet_ms});
            }
        }
    }

    double next_release_after(double now_ms, double horizon_ms) const {
        double next = horizon_ms;
        for (const auto& t : tasks) {
            double k = std::floor(now_ms / t.period_ms + 1.0);
            double r = k * t.period_ms;
            if (r > now_ms + 1e-9) next = std::min(next, r);
        }
        return next;
    }

    void run() {
        const double H = 1000.0;
        double now = 0.0;
        bool first_release = true;

        while (now < H - 1e-9 || !ready.empty()) {
            if (first_release || std::fabs(now) < 1e-9) {
                release_jobs(now, H);
                first_release = false;
            }

            if (ready.empty()) {
                double nr = next_release_after(now, H);
                if (nr >= H - 1e-9) break;
                wait(sc_time(nr - now, SC_MS));
                now = nr;
                release_jobs(now, H);
                continue;
            }

            Job j = ready.top();
            ready.pop();

            double nr = next_release_after(now, H);
            double run_ms = std::min(j.remaining_ms, nr - now);
            if (run_ms <= 1e-9) {
                release_jobs(now, H);
                ready.push(j);
                continue;
            }

            wait(sc_time(run_ms, SC_MS));
            now += run_ms;
            busy_ms += run_ms;
            j.remaining_ms -= run_ms;

            if (j.remaining_ms > 1e-9) {
                // A higher-priority release caused preemption; retain remaining work.
                ready.push(j);
            } else {
                if (now > j.deadline_ms + 1e-9) ++deadline_misses;
            }

            // Any releases that occur exactly at the current simulation time are ready.
            release_jobs(now, H);
        }

        std::cout << "ECA1422 SystemC Scheduler Model\n";
        std::cout << "Simulation horizon = " << H << " ms\n";
        std::cout << std::fixed << std::setprecision(3);
        std::cout << "Busy time = " << busy_ms << " ms\n";
        std::cout << "CPU utilization = " << (busy_ms / H) * 100.0 << "%\n";
        std::cout << "Deadline misses = " << deadline_misses << "\n";
        std::cout << "RESULT: " << (deadline_misses == 0 ? "PASS" : "FAIL") << "\n";
        sc_stop();
    }
};

int sc_main(int argc, char* argv[]) {
    ECA1422Scheduler model("eca1422_scheduler");
    sc_start();
    return 0;
}
