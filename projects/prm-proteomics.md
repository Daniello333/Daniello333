# Targeted proteomics PRM planning — MSc research

**R · DIA-NN · LC–MS/MS · peptide selection · iRT calibration**

My master's research developed an R workflow to design candidate precursor lists for parallel reaction monitoring (PRM) from a **741-protein human panel**. It combines in-silico protein digestion, peptide uniqueness and sequence constraints, experimental DIA evidence, fragment-quality ranking, retention-window crowding and cross-gradient retention-time transfer.

## Five-stage pipeline

1. Reference FASTA preparation, Trypsin / Lys-C comparison and unique-peptide selection.
2. DIA-NN experimental evidence integration, PEP-based filters and fragment scoring.
3. Top 2 / Top 3 peptide–precursor list generation.
4. Chromatographic crowding analysis and controlled peptide substitutions.
5. iRT calibration and expanded 30-minute lists using qualifying 60-minute evidence.

## Results from exported analysis tables

| Measure | Baseline | Extended |
| --- | ---: | ---: |
| Proteins with selected candidates | 596 | 609 |
| Top 2 peptides | 1,087 | 1,129 |
| Top 3 peptides | 1,493 | 1,563 |

- **13 additional proteins** received candidate coverage in the extended lists.
- **32 peptides** in the extended Top 3 list used predicted 30-minute RT because they were observed only in 60-minute data.
- Within-panel retention-time transfer validation (4,033 common peptides): **MAE 0.333 min**, **RMSE 0.424 min**, **95th-percentile absolute error 0.894 min**, **R² 0.997**.

The outputs are *candidate lists for instrument-method preparation*, not experimentally validated scheduled-PRM assays. Skyline review and experimental validation remain necessary.

## Portfolio/reproducibility status

I inspected the five R scripts and selected exported tables and figures. A curated repository-ready archive has been prepared with five scripts, minimal result summaries, images and input requirements. Large DIA-NN source reports and laboratory data were deliberately excluded. **These source files have not yet been published as a dedicated public GitHub repository**. Full reproduction requires separately supplied input files and rights to access them.

**Author:** Daniel Drabik · Jagiellonian University
