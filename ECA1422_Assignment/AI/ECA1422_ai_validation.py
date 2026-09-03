"""Reproducible synthetic AI validation for ECA1422.
The data are synthetic and are NOT field measurements.
"""
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report

SEED_DATA = 1340
SEED_SPLIT = 1422
N_PER_CLASS = 400
LABELS = ['Normal', 'Misalignment', 'Bearing Fault']

rng = np.random.default_rng(SEED_DATA)
n = N_PER_CLASS
X = np.vstack([
    np.column_stack([rng.normal(.20,.045,n), rng.normal(3.0,.45,n), rng.normal(3.0,.35,n), rng.normal(30,8,n), rng.normal(42,3,n)]),
    np.column_stack([rng.normal(.32,.05,n), rng.normal(3.8,.5,n), rng.normal(4.0,.4,n), rng.normal(60,10,n), rng.normal(45,3,n)]),
    np.column_stack([rng.normal(.48,.06,n), rng.normal(5.0,.6,n), rng.normal(5.0,.5,n), rng.normal(120,12,n), rng.normal(52,3,n)]),
])
y = np.array([LABELS[0]]*n + [LABELS[1]]*n + [LABELS[2]]*n)

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.20, stratify=y, random_state=SEED_SPLIT
)
model = DecisionTreeClassifier(max_depth=4, min_samples_leaf=8, random_state=SEED_SPLIT)
model.fit(X_train, y_train)
y_pred = model.predict(X_test)

cm = confusion_matrix(y_test, y_pred, labels=LABELS)
print('ECA1422 Synthetic AI Validation')
print('Dataset: 1200 windows (400 per class)')
print('Train/test split: 960/240')
print(f'Accuracy: {accuracy_score(y_test,y_pred)*100:.2f}%')
print('Confusion matrix (rows=actual, columns=predicted):')
print(cm)
print(classification_report(y_test, y_pred, labels=LABELS, digits=4))
print('NOTE: Synthetic validation only; not field accuracy.')
