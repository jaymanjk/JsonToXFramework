# Quick Start Guide

## Run the Console App in 3 Steps

### 1. Navigate to the Console App folder
```bash
cd src/clients/Axbus.ConsoleApp
```

### 2. Run the application
```bash
dotnet run
```

### 3. Check the output
- **CSV files**: `.\Output\Csv\`
- **Excel files**: `.\Output\Excel\`
- **Logs**: `.\logs\`

---

## Expected Output

```
[INFO ] CustomersJsonToCsv | ModuleStarted | Starting conversion
  [CustomersJsonToCsv] Converting | Files: 1/1 | Progress: 100.0%
[INFO ] ProductsJsonToExcel | ModuleStarted | Starting conversion  
  [ProductsJsonToExcel] Converting | Files: 1/1 | Progress: 100.0%

===============================================================
Axbus Conversion Summary
===============================================================
Total modules  : 2
Successful     : 2
Failed         : 0
Skipped        : 1
Total files    : 2
Total rows     : 7
Duration       : 1.23s
===============================================================
```

---

## What Gets Converted

| Module | Input | Output | Rows |
|---|---|---|---|
| CustomersJsonToCsv | `SampleData/customers.json` | `Output/Csv/customers.csv` | 6 rows (3 customers with 2, 1, and 3 orders) |
| ProductsJsonToExcel | `SampleData/products.json` | `Output/Excel/products.xlsx` | 4 rows |
| EmployeesJsonToCsv | `SampleData/employees.json` | *Disabled* | - |

---

## Troubleshooting

### "Build failed"
Run from solution root:
```bash
dotnet build
cd src/clients/Axbus.ConsoleApp
dotnet run --no-build
```

### "No files found"
Check that `SampleData` folder exists with the 3 JSON files.

### "Permission denied" or "Access denied reading file"
Set `Source.Path` to the **folder**, not a specific file, and use `FilePattern` to select files:
```json
"Source": {
  "Path": ".\\SampleData",
  "FilePattern": "customers.json",
  "ReadMode": "AllFiles"
}
```
The framework enumerates each matching file and runs a separate pipeline pass per file.

### "No plugin registered for format pair"
Ensure the build output contains `*.manifest.json` files alongside each plugin DLL.
Run a clean build (`dotnet clean && dotnet build`) to trigger a fresh copy.

---

See **README.md** for full documentation.
