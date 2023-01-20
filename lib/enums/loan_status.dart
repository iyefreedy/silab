enum LoanStatus {
  pending(name: 'Pending'),
  approved(name: 'Disetujui'),
  done(name: 'Selesai');

  final String name;
  const LoanStatus({required this.name});
}

LoanStatus describeEnum(String status) {
  if (status == 'Pending') {
    return LoanStatus.pending;
  } else if (status == 'Disetujui') {
    return LoanStatus.approved;
  } else {
    return LoanStatus.done;
  }
}
