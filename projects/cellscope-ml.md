# CellScope ML v1.0 — Single-cell RNA-seq annotation studio

**Python · scikit-learn · Streamlit · pandas · AnnData · pytest**

CellScope ML is a research-oriented, locally run application for supervised annotation of **known** scRNA-seq cell types. I developed the project to explore reproducible classification, donor-aware evaluation, dataset shift, and limitations of confidence-based prediction.

## Engineering highlights

- Local Streamlit interface, command-line workflow and Python package.
- Accepts CSV / H5AD expression matrices with validated normalization assumptions.
- Training-only gene selection, standardization and logistic-regression baseline.
- Donor-disjoint holdout when donor metadata exists; cell-based fallback explicitly flagged.
- Exports inspectable JSON model parameters rather than loading untrusted pickle models in the application.
- Automated Python tests and a cross-platform GitHub Actions workflow in the source distribution.

## Reported evaluation

The bundled Kang 2018 reference-model validation file records **macro F1 = 0.9947** and **accuracy = 0.995** on a single donor-disjoint holdout (600 cells / 2 donors), using four predefined immune-cell classes. This is an internal evaluation on one annotated dataset, **not** independent biological or clinical validation. Synthetic demo metrics are not used as scientific performance claims.

Research extensions examined interferon-marker ablations, donor/condition shift and exploratory open-set uncertainty. The app's `uncertain` label is only a heuristic confidence flag and **cannot identify previously unseen cell types reliably**.

## Portfolio/reproducibility status

The complete code, Python tests, synthetic examples and validation JSON were inspected from the submitted **CellScope ML v1.0** source archive. A clean, small repository-ready export has been prepared, excluding `.venv`, caches and large private data. A [selected original source module and Python tests](https://github.com/Daniello333/BioinformaticsProject/tree/claude/bioinformatics-project-access-3dtgkg/cellscope-ml) are now public. The full application and complete test suite are **not** yet uploaded.

**Author:** Daniel Drabik
