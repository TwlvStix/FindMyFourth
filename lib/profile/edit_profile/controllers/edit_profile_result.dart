// ═══════════════════════════════════════════════════════════════════════════
// SAVE PROFILE RESULTS
// ═══════════════════════════════════════════════════════════════════════════

sealed class EditProfileSaveResult {
  const EditProfileSaveResult();
}

class EditProfileSaveSuccess extends EditProfileSaveResult {
  const EditProfileSaveSuccess();
}

class EditProfileSaveValidationError extends EditProfileSaveResult {
  final String code;
  final String message;
  const EditProfileSaveValidationError(this.code, this.message);
}

class EditProfileSaveFailure extends EditProfileSaveResult {
  final String type;
  final String message;
  const EditProfileSaveFailure(this.type, this.message);
}

// ═══════════════════════════════════════════════════════════════════════════
// DELETE ACCOUNT RESULTS
// ═══════════════════════════════════════════════════════════════════════════

sealed class EditProfileDeleteResult {
  const EditProfileDeleteResult();
}

class EditProfileDeleteSuccess extends EditProfileDeleteResult {
  const EditProfileDeleteSuccess();
}

class EditProfileDeleteCancelled extends EditProfileDeleteResult {
  const EditProfileDeleteCancelled();
}

class EditProfileDeleteFailure extends EditProfileDeleteResult {
  final String type;
  final String message;
  const EditProfileDeleteFailure(this.type, this.message);
}
