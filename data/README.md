# Data

The original university dataset is not included because redistribution rights are unclear.

The pipeline expects a whitespace-delimited file with 10 columns in this order:

1. `CountyName`
2. `State`
3. `Bird`
4. `Equine`
5. `Farms`
6. `Area`
7. `Population`
8. `HumanDensity`
9. `PosBirdRate`
10. `PosEquineRate`

Run the project by passing the local dataset path:

```bash
Rscript run_analysis.R /path/to/Dataset8.txt
```
