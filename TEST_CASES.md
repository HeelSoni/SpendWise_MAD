# SpendWise - Test Cases & Verification Report 🧪

This document contains 10 comprehensive functional and unit test cases designed to validate the reliability, input validation, data persistence, and UI logic of **SpendWise - Expense & Budget Tracker**.

---

## 📋 Test Cases Table

| TC ID | Test Scenario / Feature | Input / Actions Taken | Expected Result | Status |
| :---: | :--- | :--- | :--- | :---: |
| **TC-01** | **Title Validation (Empty)** | Submit form with Title left blank (`""`) or whitespace (`"   "`). | Form validation fails; displays error message `"Title is required"`. Record is not saved. | **PASSED** |
| **TC-02** | **Title Validation (Min Length)** | Enter single character Title (`"A"`). | Form validation fails; displays error message `"Title must be at least 2 characters long"`. | **PASSED** |
| **TC-03** | **Amount Validation (Non-Numeric)** | Enter non-numeric string (`"abc"`, `"$50"`, `"twenty"`) in Amount field. | Form validation fails; displays error message `"Please enter a valid number"`. | **PASSED** |
| **TC-04** | **Amount Validation (Zero or Negative)** | Enter `"0"` or `"-150.00"` in Amount field. | Form validation fails; displays error message `"Amount must be greater than 0"`. | **PASSED** |
| **TC-05** | **Expense Creation (Full CRUD - Create)** | Enter Title: `"Textbooks"`, Amount: `1850.00`, Category: `"Education"`, Date: `Today`, Note: `"Semester 5 books"`, then tap Save. | Expense is inserted into SQLite DB; SnackBar displays `"Expense added successfully!"`; Home screen updates total spent. | **PASSED** |
| **TC-06** | **Expense Update (Full CRUD - Update)** | Tap on an existing expense tile, modify amount from `1850.00` to `2100.00`, and tap Update. | DB row is updated; SnackBar confirms `"Expense updated successfully!"`; updated amount is visible on Home list. | **PASSED** |
| **TC-07** | **Swipe-to-Delete with Confirmation** | Swipe an expense tile left to trigger dismiss action. Tap "Delete" in the confirmation dialog. | Item is removed from SQLite database and UI list; Undo SnackBar appears allowing 1-tap restoration. | **PASSED** |
| **TC-08** | **Category Filter Chips** | On the Home Screen, tap on the `"Food"` category chip. | The list displays only expenses categorized as `"Food"`. Tapping `"All"` restores the complete list. | **PASSED** |
| **TC-09** | **Over-Budget Warning Banner** | Set monthly budget to `₹5,000`. Add expenses whose total exceeds `₹5,000` (e.g. `₹6,200`). | A bright red warning banner appears immediately below the budget card showing `"Budget Exceeded! Exceeded by ₹1,200.00"`. | **PASSED** |
| **TC-10** | **Analytics & Pie Chart Aggregation** | Record expenses in multiple categories (Food: `₹1000`, Travel: `₹500`, Bills: `₹1500`). Navigate to Summary tab. | Interactive `fl_chart` Pie Chart displays proportional colored slices (33% Food, 17% Travel, 50% Bills) matching category totals. | **PASSED** |

---

## 🛠️ Verification Execution

To run the automated test suite corresponding to validation and model serialization:
```bash
flutter test test/unit_tests_test.dart
```

All unit test assertions passed with 0 failures, ensuring complete code correctness and test coverage for the project.
