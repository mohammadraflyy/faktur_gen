/// Template style for invoice PDF.
enum InvoiceTemplate {
  modern('Modern', 'Header biru dengan tabel bergaris'),
  classic('Classic', 'Layout formal dengan border tebal'),
  minimal('Minimal', 'Bersih tanpa warna, fokus konten');

  final String label;
  final String description;
  const InvoiceTemplate(this.label, this.description);
}

/// Template style for struk/receipt PDF.
enum StrukTemplate {
  standard('Standard', 'Format struk lengkap dengan logo'),
  compact('Compact', 'Ringkas tanpa logo, hemat kertas');

  final String label;
  final String description;
  const StrukTemplate(this.label, this.description);
}

/// Configuration for document template customization.
class DocTemplateConfig {
  InvoiceTemplate invoiceTemplate;
  StrukTemplate strukTemplate;
  int primaryColorValue; // stored as int (0xAARRGGBB)
  bool showLogo;
  bool showSignature;
  bool showBankInfo;
  bool showNpwp;
  bool logoCenter; // true=center, false=left

  DocTemplateConfig({
    this.invoiceTemplate = InvoiceTemplate.modern,
    this.strukTemplate = StrukTemplate.standard,
    this.primaryColorValue = 0xFF2563EB,
    this.showLogo = true,
    this.showSignature = true,
    this.showBankInfo = true,
    this.showNpwp = true,
    this.logoCenter = false,
  });

  Map<String, dynamic> toMap() => {
        'invoiceTemplate': invoiceTemplate.name,
        'strukTemplate': strukTemplate.name,
        'primaryColorValue': primaryColorValue,
        'showLogo': showLogo,
        'showSignature': showSignature,
        'showBankInfo': showBankInfo,
        'showNpwp': showNpwp,
        'logoCenter': logoCenter,
      };

  factory DocTemplateConfig.fromMap(Map<String, dynamic> m) {
    return DocTemplateConfig(
      invoiceTemplate: InvoiceTemplate.values.firstWhere(
        (e) => e.name == m['invoiceTemplate'],
        orElse: () => InvoiceTemplate.modern,
      ),
      strukTemplate: StrukTemplate.values.firstWhere(
        (e) => e.name == m['strukTemplate'],
        orElse: () => StrukTemplate.standard,
      ),
      primaryColorValue: m['primaryColorValue'] ?? 0xFF2563EB,
      showLogo: m['showLogo'] ?? true,
      showSignature: m['showSignature'] ?? true,
      showBankInfo: m['showBankInfo'] ?? true,
      showNpwp: m['showNpwp'] ?? true,
      logoCenter: m['logoCenter'] ?? false,
    );
  }
}
