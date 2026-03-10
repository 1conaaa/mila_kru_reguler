import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/api/ApiHelperMetodePembayaran.dart';
import 'package:mila_kru_reguler/api/ApiHelperPersenFeeOTA.dart';
import 'package:mila_kru_reguler/api/ApiPersenPremiKru..dart';
import 'package:mila_kru_reguler/api/ApiHelperPremiPosisiKru.dart';
import 'package:mila_kru_reguler/api/ApiHelperKruBis.dart';
import 'package:mila_kru_reguler/api/ApiHelperListKota.dart';
import 'package:mila_kru_reguler/api/ApiHelperOperasiHarianBus.dart';
import 'package:mila_kru_reguler/api/ApiHelperJenisPaket.dart';
import 'package:mila_kru_reguler/api/ApiHelperTagTransaksi.dart';
import 'package:mila_kru_reguler/api/ApiHelperRuteTrayekUrutan.dart';
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';
import 'package:mila_kru_reguler/models/user.dart';

enum StepStatus { pending, loading, success, error }

class LoadingStep {
  final String title;
  final Future<void> Function() action;
  StepStatus status;

  LoadingStep({
    required this.title,
    required this.action,
    this.status = StepStatus.pending,
  });
}

class InitialDataLoadingPage extends StatefulWidget {
  final String token;
  final User user;

  const InitialDataLoadingPage({
    Key? key,
    required this.token,
    required this.user,
  }) : super(key: key);

  @override
  State<InitialDataLoadingPage> createState() =>
      _InitialDataLoadingPageState();
}

class _InitialDataLoadingPageState
    extends State<InitialDataLoadingPage> {

  final List<LoadingStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _prepareSteps();
    _startLoading();
  }

  void _prepareSteps() {
    final token = widget.token;
    final user = widget.user;

    final int idBus = user.idBus;
    final int idGarasi = user.idGarasi;
    final String noPol = user.noPol ?? "";
    final String jenisTrayek = user.jenisTrayek ?? "";
    final String kodeTrayek = user.kodeTrayek ?? "";
    final String kelasBusRaw = user.kelasBus ?? "";

    final kelasBusFinal = kelasBusRaw.replaceAll(" - ", "-");

    _steps.addAll([
      LoadingStep(
        title: "Memuat Data Kru Bis",
        action: () => ApiHelperKruBis.requestKruBisAPI(
            token, idBus, noPol, idGarasi, context),
      ),
      LoadingStep(
        title: "Memuat Persen Premi Kru",
        action: () => ApiHelperPersenPremiKru
            .requestListPersenPremiAPI(token, kodeTrayek),
      ),
      LoadingStep(
        title: "Memuat Data Kota",
        action: () => ApiHelperListKota
            .requestListKotaAPI(token, kodeTrayek),
      ),
      LoadingStep(
        title: "Memuat Rute Trayek",
        action: () => ApiHelperRuteTrayekUrutan
            .requestRuteTrayekUrutanAPI(token, kodeTrayek),
      ),
      LoadingStep(
        title: "Memuat Metode Pembayaran",
        action: () => ApiHelperMetodePembayaran
            .fetchAndStoreMetodePembayaran(token),
      ),
      LoadingStep(
        title: "Memuat Premi Posisi Kru",
        action: () => ApiHelperPremiPosisiKru
            .requestListPremiPosisiKruAPI(
            token, jenisTrayek, kelasBusFinal),
      ),
      LoadingStep(
        title: "Memuat Operasi Harian Bus",
        action: () => ApiHelperOperasiHarianBus
            .addListOperasiHarianBusAPI(
            token, idBus, noPol, kodeTrayek),
      ),
      LoadingStep(
        title: "Memuat Jenis Paket",
        action: () => ApiHelperJenisPaket
            .addListJenisPaketAPI(token),
      ),
      LoadingStep(
        title: "Memuat Tag Transaksi",
        action: () => ApiHelperTagTransaksi
            .fetchAndStoreTagTransaksi(token),
      ),
      LoadingStep(
        title: "Memuat Fee OTA",
        action: () => ApiHelperPersenFeeOTA
            .requestListPersenFeeOTAAPI(token),
      ),
    ]);
  }

  Future<void> _startLoading() async {
    final penjualanData =
    await PenjualanTiketService.instance.getDataPenjualan();

    if (penjualanData.isNotEmpty) {
      _finish();
      return;
    }

    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;

      setState(() {
        _steps[i].status = StepStatus.loading;
      });

      try {
        await _steps[i].action();

        if (!mounted) return;

        setState(() {
          _steps[i].status = StepStatus.success;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _steps[i].status = StepStatus.error;
        });
      }
    }

    _finish();
  }

  void _finish() {
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/',
      arguments: {
        'welcomeMessage':
        'Salam ${widget.user.namaLengkap}, '
            'Anda sudah terdaftar bertugas pada Bis '
            '(${widget.user.idBus})-${widget.user.noPol} '
            'Trayek ${widget.user.namaTrayek}. '
            'Selamat bertugas. Bismillah.',
      },
    );
  }

  Widget _buildIcon(StepStatus status) {
    switch (status) {
      case StepStatus.loading:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case StepStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case StepStatus.error:
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.radio_button_unchecked,
            color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/mila_logo.png',
                width: 120,
              ),
              const SizedBox(height: 30),
              const Text(
                "Menyiapkan Data Awal...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];

                    return Card(
                      child: ListTile(
                        leading: _buildIcon(step.status),
                        title: Text(step.title),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}