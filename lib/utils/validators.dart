/// Utility class providing form input validators for the SpendWise app.
///
/// Each validation method returns null if the input is valid, or a descriptive
/// error String if the validation fails. Designed for easy unit testing and form validation.
class Validators {
  /// Validates the expense title input.
  ///
  /// Criteria:
  /// - Cannot be null
  /// - Cannot be empty or contain only whitespace
  /// - Must be at least 2 characters long for descriptive accuracy
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 2) {
      return 'Title must be at least 2 characters long';
    }
    return null;
  }

  /// Validates the expense amount input.
  ///
  /// Criteria:
  /// - Cannot be null
  /// - Cannot be empty or contain only whitespace
  /// - Must be a valid numerical value (parsable as double)
  /// - Must be strictly greater than 0 (no zero or negative expenses)
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final parsedAmount = double.tryParse(value.trim());
    if (parsedAmount == null) {
      return 'Please enter a valid number';
    }

    if (parsedAmount <= 0) {
      return 'Amount must be greater than 0';
    }

    return null;
  }

  /// Validates the selected expense category.
  ///
  /// Criteria:
  /// - Must be one of the known supported categories in SpendWise.
  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category is required';
    }
    return null;
  }

  /// Validates the expense date input.
  ///
  /// Criteria:
  /// - Date cannot be null.
  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    return null;
  }

  /// Validates the monthly budget input.
  ///
  /// Criteria:
  /// - Cannot be empty
  /// - Must be a valid positive number or 0
  static String? validateBudget(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Budget amount is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed < 0) {
      return 'Budget cannot be negative';
    }
    return null;
  }
}
