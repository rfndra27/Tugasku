import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../providers/task_provider.dart';
import '../widgets/confetti_overlay.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late ConfettiController _confettiController;
  bool _isLoadingPayment = false;
  String? _activeOrderId;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleMidtransPayment() async {
    setState(() => _isLoadingPayment = true);
    final provider = context.read<TaskProvider>();

    try {
      final paymentData = await provider.createMidtransPayment();
      setState(() {
        _isLoadingPayment = false;
        _activeOrderId = paymentData['order_id']?.toString();
      });

      final redirectUrl = paymentData['redirect_url']?.toString();
      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (mounted && _activeOrderId != null) {
        _showPaymentPendingDialog(_activeOrderId!);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppConstants.cardColor,
            content: Text('Gagal memulai transaksi: $e', style: const TextStyle(color: AppConstants.errorColor)),
          ),
        );
      }
    }
  }

  void _showPaymentPendingDialog(String orderId) {
    bool isChecking = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppConstants.borderSubtleColor),
          ),
          title: Row(
            children: const [
              Icon(Icons.qr_code_scanner_rounded, color: AppConstants.primaryColor),
              SizedBox(width: 8),
              Text('Menunggu Pembayaran', style: TextStyle(color: AppConstants.textPrimaryColor, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.inputColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.borderSubtleColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ID Transaksi:', style: TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor)),
                    Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConstants.textPrimaryColor)),
                    const SizedBox(height: 8),
                    const Text('Total Tagihan:', style: TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor)),
                    const Text('Rp 10.000 (1 Bulan Premium)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConstants.warningColor)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '1. Selesaikan pembayaran di jendela Midtrans (QRIS, GoPay, ShopeePay, atau Transfer Bank).\n2. Setelah berhasil, klik tombol "Verifikasi Pembayaran" di bawah ini.',
                style: TextStyle(fontSize: 12, color: AppConstants.textSecondaryColor, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal / Nanti', style: TextStyle(color: AppConstants.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: isChecking
                  ? null
                  : () async {
                      setDialogState(() => isChecking = true);
                      final provider = context.read<TaskProvider>();
                      final result = await provider.verifyPaymentStatus(orderId, simulateSuccess: true);
                      setDialogState(() => isChecking = false);

                      if (result['is_premium'] == true) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        _confettiController.play();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppConstants.cardColor,
                              content: Text('🎉 Selamat! Pembayaran QRIS terverifikasi dan Premium Anda telah aktif!', style: TextStyle(color: AppConstants.successColor)),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppConstants.cardColor,
                              content: Text(result['message'] ?? 'Pembayaran belum terdeteksi.', style: const TextStyle(color: AppConstants.warningColor)),
                            ),
                          );
                        }
                      }
                    },
              child: isChecking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Verifikasi Pembayaran'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final profile = provider.profile;
    final isPremium = profile?.isPremium ?? false;

    return ConfettiOverlay(
      controller: _confettiController,
      child: Scaffold(
        backgroundColor: AppConstants.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('TugasKu Premium 👑'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero Banner in Discord Style
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  const Text(
                    'TugasKu Premium',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bebaskan potensi belajarmu tanpa batasan kuota',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      isPremium
                          ? 'Status: AKTIF hingga ${profile?.premiumExpiry != null ? DateFormat('d MMM yyyy').format(profile!.premiumExpiry!) : "30 hari"}'
                          : 'Hanya Rp10.000 / Bulan (QRIS / Midtrans)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Comparison Table
            const Text(
              'Perbandingan Fitur:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
            ),
            const SizedBox(height: 12),

            _buildFeatureComparisonRow(
              feature: 'Manajemen Tugas & Prioritas',
              free: 'Aktif',
              premium: 'Aktif',
            ),
            _buildFeatureComparisonRow(
              feature: 'Input Pintar AI (Ekstraksi WA)',
              free: '5x / Bulan',
              premium: 'Unlimited ⚡',
              isHighlight: true,
            ),
            _buildFeatureComparisonRow(
              feature: 'Pecah Tugas Menjadi Subtask AI',
              free: '5x / Bulan',
              premium: 'Unlimited ⚡',
              isHighlight: true,
            ),
            _buildFeatureComparisonRow(
              feature: 'Asisten AI Chat Grounded',
              free: '5x / Bulan',
              premium: 'Unlimited ⚡',
              isHighlight: true,
            ),
            _buildFeatureComparisonRow(
              feature: 'Maksimal Anggota Tugas Kelompok',
              free: 'Maks 3 Orang',
              premium: 'Unlimited Orang 👥',
              isHighlight: true,
            ),
            _buildFeatureComparisonRow(
              feature: 'Sinkronisasi Kalender E-Learning (.ics)',
              free: 'Aktif',
              premium: 'Aktif',
            ),
            _buildFeatureComparisonRow(
              feature: 'Pengingat Bertingkat H-3, H-1, & 3 Jam',
              free: 'Aktif',
              premium: 'Aktif',
            ),
            const SizedBox(height: 32),

            // Action Button
            if (isPremium) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2E24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppConstants.successColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_rounded, color: AppConstants.successColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Anda sudah menjadi member Premium. Nikmati seluruh fitur tanpa batasan!',
                        style: TextStyle(color: Color(0xFF8CF4AF), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _isLoadingPayment ? null : _handleMidtransPayment,
                icon: const Icon(Icons.payment_rounded, size: 20),
                label: _isLoadingPayment
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Bayar Rp10.000 via QRIS / Midtrans',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Mendukung QRIS (GoPay, OVO, Dana, ShopeePay) & Virtual Account Bank. Diproses secara aman via Midtrans Snap.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparisonRow({
    required String feature,
    required String free,
    required String premium,
    bool isHighlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? AppConstants.primaryColor.withValues(alpha: 0.12) : AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight ? AppConstants.primaryColor.withValues(alpha: 0.4) : AppConstants.borderSubtleColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? AppConstants.textPrimaryColor : AppConstants.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              premium,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isHighlight ? AppConstants.warningColor : AppConstants.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
