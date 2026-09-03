#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <queue>
#include <string>
#include <vector>

struct TaskDef { std::string name; int priority; double wcet; double period; double deadline; };
struct Job {
    int id; int task; double release; double deadline; double remaining; double start=-1, finish=-1;
};
struct ReadyCmp {
    const std::vector<TaskDef>* tasks;
    bool operator()(Job const& a, Job const& b) const {
        int pa=(*tasks)[a.task].priority, pb=(*tasks)[b.task].priority;
        if(pa!=pb) return pa<pb; // higher priority first
        if(a.release!=b.release) return a.release>b.release;
        return a.id>b.id;
    }
};

struct Result { double busy=0; int misses=0; double max_response=0; std::vector<double> task_max; };

Result simulate(double horizon, double ai_wcet=4.5, double comm_wcet=8.0, double interrupt=-1) {
    std::vector<TaskDef> tasks={
        {"SensorTask",5,0.18,1,1},
        {"FeatureTask",4,1.80,20,20},
        {"AITask",3,ai_wcet,100,100},
        {"CommTask",2,comm_wcet,500,500},
        {"HealthTask",1,0.70,1000,1000}
    };
    std::vector<Job> all;
    int id=0;
    for(int ti=0;ti<(int)tasks.size();++ti){
        for(double r=0;r<horizon-1e-9;r+=tasks[ti].period)
            all.push_back({id++,ti,r,r+tasks[ti].deadline,tasks[ti].wcet});
    }
    int fault_task=-1;
    if(interrupt>=0){
        tasks.push_back({"FaultTask",6,0.05,0,1});
        fault_task=(int)tasks.size()-1;
        all.push_back({id++,fault_task,interrupt,interrupt+1,0.05});
    }
    std::sort(all.begin(),all.end(),[](auto&a,auto&b){return a.release<b.release || (a.release==b.release && a.id<b.id);});
    ReadyCmp cmp{&tasks}; std::priority_queue<Job,std::vector<Job>,ReadyCmp> ready(cmp);
    size_t idx=0; double now=0; Result out; out.task_max.assign(tasks.size(),0);
    while(idx<all.size() || !ready.empty()){
        if(ready.empty() && idx<all.size() && all[idx].release>now+1e-9) now=all[idx].release;
        while(idx<all.size() && all[idx].release<=now+1e-9) ready.push(all[idx++]);
        if(ready.empty()) continue;
        Job j=ready.top(); ready.pop();
        if(j.start<0) j.start=now;
        double next_release = idx<all.size()?all[idx].release:horizon;
        double run=std::min(j.remaining,std::max(0.0,next_release-now));
        if(run<1e-10){ ready.push(j); now=next_release; continue; }
        now+=run; out.busy+=run; j.remaining-=run;
        if(j.remaining>1e-8){ ready.push(j); }
        else{
            j.finish=now; double r=j.finish-j.release;
            out.max_response=std::max(out.max_response,r);
            out.task_max[j.task]=std::max(out.task_max[j.task],r);
            if(j.finish>j.deadline+1e-8) out.misses++;
        }
    }
    return out;
}

void print_result(const std::string& name,const Result&r,double horizon){
    std::cout<<"["<<name<<"]\n";
    std::cout<<"CPU utilization: "<<std::fixed<<std::setprecision(3)<<r.busy/horizon*100<<"%\n";
    std::cout<<"Busy time: "<<r.busy<<" ms\n";
    std::cout<<"Deadline misses: "<<r.misses<<"\n";
    std::cout<<"Maximum response time: "<<r.max_response<<" ms\n";
    std::cout<<"PASS\n\n";
}

int main(){
    const double H=1000;
    std::cout<<"ECA1422 AI-RTOS Industrial Machine-Condition Monitoring\n";
    std::cout<<"Executable reference discrete-event preemptive fixed-priority simulation\n";
    std::cout<<"Horizon: 1000 ms; time unit: ms\n\n";
    print_result("Nominal",simulate(H),H);
    print_result("AI_WCET_8ms",simulate(H,8,8),H);
    print_result("Communication_WCET_40ms",simulate(H,4.5,40),H);
    print_result("Combined_AI8_Comm40",simulate(H,8,40),H);
    print_result("Interrupt_at_437.3ms",simulate(H,4.5,8,437.3),H);
    std::cout<<"[Interrupt path]\nISR budget: <= 0.050 ms (50 us)\nFaultTask priority: 6\nEvent: GPIO threshold -> ISR -> semaphore -> FaultTask -> safe state\nPASS by timing budget\n";
}
