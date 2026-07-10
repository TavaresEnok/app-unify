part of '../diagnostic_02_page.dart';

class DiagnosticScreen extends StatelessWidget {
  final DiagState state;
  final VoidCallback onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onSharePdf;

  // WiFi Management Controller
  final WifiManagementController? wifiController;

  // Troubleshooter
  final real_state.DiagnosticoState? realState;

  static String? _safeResultString(dynamic result) {
    if (result == null) return null;
    if (result is String) return result;
    if (result is Map) {
      return result['display'] as String? ??
          result['displayText'] as String? ??
          result['stateStr'] as String? ??
          result.toString();
    }
    return result.toString();
  }

  const DiagnosticScreen({
    super.key,
    required this.state,
    required this.onCancel,
    this.onRetry,
    this.onSharePdf,
    this.wifiController,
    this.realState,
  });

  Color _rssiColor(int r) => r >= -50
      ? DiagnosticTheme.green
      : r >= -70
          ? DiagnosticTheme.orange
          : DiagnosticTheme.red;
  Color _battColor(int b) => b > 50
      ? DiagnosticTheme.green
      : b > 20
          ? DiagnosticTheme.orange
          : DiagnosticTheme.red;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF02060D),
      child: HoloBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: onCancel,
            ),
            title: const Text(
              'DIAGNÓSTICO',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            actions: [
              if (onSharePdf != null)
                IconButton(
                  icon: const Icon(
                    Icons.share_rounded,
                    color: DiagnosticTheme.cyan,
                  ),
                  onPressed: onSharePdf,
                  tooltip: 'Compartilhar PDF',
                ),
              if (state.isRunning)
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'PARAR',
                    style: TextStyle(
                      color: DiagnosticTheme.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // Step progress
                  StepProgressBar(
                    currentStep: state.currentStep,
                    completedSteps: state.completedSteps,
                    isRunning: state.isRunning,
                  ),
                  const SizedBox(height: 16),
                  // Status
                  Center(
                    child: Text(
                      state.status,
                      style: const TextStyle(
                        color: DiagnosticTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Live Graph
                  LiveSpeedGraph(
                    downloadData: state.downloadHistory,
                    uploadData: state.uploadHistory,
                    currentSpeed: state.currentSpeed,
                    phase: state.speedPhase,
                    downloadSpeed: state.downloadSpeed,
                    uploadSpeed: state.uploadSpeed,
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Ping',
                          value: '${state.ping}',
                          unit: 'ms',
                          icon: Icons.timer_outlined,
                          color: DiagnosticTheme.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Jitter',
                          value: state.jitter.toStringAsFixed(1),
                          unit: 'ms',
                          icon: Icons.graphic_eq,
                          color: DiagnosticTheme.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'LAN',
                          value: '${state.lan.length}',
                          unit: 'devices',
                          icon: Icons.devices,
                          color: DiagnosticTheme.purple,
                        ),
                      ),
                    ],
                  ),
                  // Sections
                  _buildConnectionJourneySection(),
                  _buildDeviceDetailsSection(),
                  _buildWifiDetailsSection(),
                  _buildOnuDetailsSection(),
                  _buildLanDetailsSection(),
                  _buildDeviceSection(),
                  _buildWifiSection(),
                  _buildOnuSection(),
                  _buildConnSection(),
                  _buildTracertSection(),
                  _buildWifiManagementSection(),
                  _buildTroubleshooterSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceSection() {
    final d = state.device;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Dispositivo',
          icon: Icons.smartphone,
          color: DiagnosticTheme.gold,
          hasData: d != null,
        ),
        if (d == null)
          const WaitingBox()
        else
          HoloCard(
            isScanning: state.isRunning && state.currentStep == DiagStep.device,
            accent: DiagnosticTheme.gold,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            _battColor(d.batteryLevel).withAlpha(60),
                            _battColor(d.batteryLevel).withAlpha(10),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        d.isCharging
                            ? Icons.battery_charging_full_rounded
                            : Icons.battery_std_rounded,
                        color: _battColor(d.batteryLevel),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.batteryLevel >= 0 ? '${d.batteryLevel}%' : '--',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _battColor(d.batteryLevel),
                          ),
                        ),
                        Text(
                          d.isCharging ? 'Carregando' : 'Na bateria',
                          style: const TextStyle(
                            color: DiagnosticTheme.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DiagnosticDataRow(
                  icon: Icons.phone_android_rounded,
                  label: 'Modelo',
                  value: d.model,
                  color: DiagnosticTheme.gold,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWifiSection() {
    final w = state.wifi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Wi-Fi',
          icon: Icons.wifi,
          color: DiagnosticTheme.pink,
          hasData: w != null,
        ),
        if (w == null)
          const WaitingBox()
        else
          HoloCard(
            isScanning: state.isRunning && state.currentStep == DiagStep.wifi,
            accent: DiagnosticTheme.pink,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            _rssiColor(w.rssi).withAlpha(60),
                            _rssiColor(w.rssi).withAlpha(10),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${w.rssi}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _rssiColor(w.rssi),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.ssid,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${w.quality} • ${w.frequency}',
                            style: TextStyle(
                              color: _rssiColor(w.rssi),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DiagnosticDataRow(
                  icon: Icons.computer_rounded,
                  label: 'IP Local',
                  value: w.localIp,
                  color: DiagnosticTheme.green,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOnuSection() {
    final o = state.onu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'ONU Fibra',
          icon: Icons.router,
          color: DiagnosticTheme.purple,
          hasData: o != null,
        ),
        if (o == null)
          const WaitingBox()
        else
          HoloCard(
            isScanning: state.isRunning && state.currentStep == DiagStep.onu,
            accent: DiagnosticTheme.purple,
            child: Column(
              children: [
                DiagnosticDataRow(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Sinal RX',
                  value: '${o.signalRx} dBm',
                  color: DiagnosticTheme.green,
                ),
                DiagnosticDataRow(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Sinal TX',
                  value: '${o.signalTx} dBm',
                  color: DiagnosticTheme.purple,
                ),
                DiagnosticDataRow(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperatura',
                  value: '${o.temperature}°C',
                  color: DiagnosticTheme.orange,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildConnSection() {
    final c = state.conn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Conectividade',
          icon: Icons.public,
          color: DiagnosticTheme.orange,
          hasData: c != null,
        ),
        if (c == null)
          const WaitingBox()
        else
          HoloCard(
            isScanning:
                state.isRunning && state.currentStep == DiagStep.connectivity,
            accent: DiagnosticTheme.orange,
            child: Column(
              children: [
                DiagnosticDataRow(
                  icon: Icons.router_rounded,
                  label: 'Ping Roteador',
                  value: '${c.pingRouter} ms',
                  color: DiagnosticTheme.green,
                ),
                DiagnosticDataRow(
                  icon: Icons.public_rounded,
                  label: 'Ping Google',
                  value: '${c.pingGoogle} ms',
                  color: DiagnosticTheme.cyan,
                ),
                DiagnosticDataRow(
                  icon: Icons.business_rounded,
                  label: 'Provedor',
                  value: c.provider,
                  color: DiagnosticTheme.pink,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTracertSection() {
    final hasData = state.tracert.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Traceroute (${state.tracert.length})',
          icon: Icons.route,
          color: DiagnosticTheme.gold,
          hasData: hasData,
        ),
        if (!hasData)
          const WaitingBox()
        else
          HoloCard(
            isScanning:
                state.isRunning && state.currentStep == DiagStep.tracert,
            accent: DiagnosticTheme.gold,
            child: Column(
              children: state.tracert.map((h) {
                final c = h.latency < 30
                    ? DiagnosticTheme.green
                    : h.latency < 80
                        ? DiagnosticTheme.orange
                        : DiagnosticTheme.red;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [c.withAlpha(60), c.withAlpha(15)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${h.hop}',
                            style: TextStyle(
                              color: c,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(h.ip, style: const TextStyle(fontSize: 11)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: c.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${h.latency}ms',
                          style: TextStyle(
                            color: c,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildWifiManagementSection() {
    if (wifiController == null) return const SizedBox.shrink();

    return ValueListenableBuilder<WifiState>(
      valueListenable: wifiController!,
      builder: (context, state, _) {
        final loadingWifi = state.isLoading;
        final wifiError = state.error;
        final wifiNetworks = state.networks;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(
              title: 'Gerenciar WiFi (TR-069)',
              icon: Icons.settings_remote_rounded,
              color: DiagnosticTheme.cyan,
              hasData:
                  wifiNetworks.isNotEmpty || wifiError != null || !loadingWifi,
            ),
            HoloCard(
              isScanning: loadingWifi,
              accent: DiagnosticTheme.cyan,
              child: loadingWifi
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: DiagnosticTheme.cyan,
                        ),
                      ),
                    )
                  : wifiError != null
                      ? Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: DiagnosticTheme.red,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                wifiError,
                                style:
                                    const TextStyle(color: DiagnosticTheme.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    wifiController!.fetchNetworks(),
                                icon: const Icon(
                                  Icons.refresh,
                                  color: DiagnosticTheme.cyan,
                                ),
                                label: const Text(
                                  'Tentar novamente',
                                  style: TextStyle(color: DiagnosticTheme.cyan),
                                ),
                              ),
                            ],
                          ),
                        )
                      : wifiNetworks.isEmpty
                          ? Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.wifi_find,
                                    color: DiagnosticTheme.textDim,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Buscar redes WiFi do roteador via TR-069',
                                    style: TextStyle(
                                        color: DiagnosticTheme.textDim),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DiagnosticTheme.cyan,
                                    ),
                                    onPressed: () =>
                                        wifiController!.fetchNetworks(),
                                    icon: const Icon(Icons.search,
                                        color: Colors.black),
                                    label: const Text(
                                      'Buscar Redes WiFi',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: wifiNetworks.map((network) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: DiagnosticTheme.bg2,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: DiagnosticTheme.cyan.withAlpha(50),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        network.frequency.contains('5')
                                            ? Icons.wifi
                                            : Icons.wifi_2_bar,
                                        color: network.enabled
                                            ? DiagnosticTheme.green
                                            : DiagnosticTheme.textDim,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              network.ssid,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              network.frequency,
                                              style: const TextStyle(
                                                color: DiagnosticTheme.textDim,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: DiagnosticTheme.cyan,
                                        ),
                                        onPressed: () => _showEditWifiDialog(
                                            context, network),
                                        tooltip: 'Editar WiFi',
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
            ),
          ],
        );
      },
    );
  }

  void _showEditWifiDialog(BuildContext context, WifiNetwork network) {
    if (wifiController == null) return;

    final ssidController = TextEditingController(text: network.ssid);
    final passwordController = TextEditingController(text: network.password);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DiagnosticTheme.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit, color: DiagnosticTheme.cyan),
            const SizedBox(width: 10),
            Text(
              'Editar ${network.frequency}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'SSID (Nome da Rede)',
                labelStyle: TextStyle(color: DiagnosticTheme.textDim),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: DiagnosticTheme.textDim),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: DiagnosticTheme.cyan),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                labelStyle: TextStyle(color: DiagnosticTheme.textDim),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: DiagnosticTheme.textDim),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: DiagnosticTheme.cyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: DiagnosticTheme.textDim),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DiagnosticTheme.cyan,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              wifiController!.updateWifi(
                context, // Pass context for SnackBar
                network.id,
                ssidController.text,
                passwordController.text,
              );
            },
            child: const Text(
              'Salvar Alterações',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshooterSection() {
    if (realState == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        TroubleshooterCard(
          state: realState!,
          onRetry: onRetry ?? () {},
          isDarkLayout: true,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARSING HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  // _parseResultLine REMOVED - Using DiagnosticUtils.parseResultLine instead

  Color _getStatusColor(real_state.TestStatus status) {
    return DiagnosticUtils.getStatusColor(
      status,
      success: DiagnosticTheme.green,
      running: DiagnosticTheme.cyan,
      error: DiagnosticTheme.red,
      pending: DiagnosticTheme.textDim,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTION JOURNEY CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConnectionJourneySection() {
    if (realState == null) return const SizedBox.shrink();

    final results = realState!.testResultsDisplay;

    final wifiStatus =
        results['wifiInfo']?['status'] as real_state.TestStatus? ??
            real_state.TestStatus.pending;
    final wifiResult = _safeResultString(results['wifiInfo']?['result']);
    final gatewayStatus =
        results['pingGateway']?['status'] as real_state.TestStatus? ??
            real_state.TestStatus.pending;
    final gatewayResult = _safeResultString(results['pingGateway']?['result']);
    final ipStatus = results['publicIp']?['status'] as real_state.TestStatus? ??
        real_state.TestStatus.pending;
    final ipResult = _safeResultString(results['publicIp']?['result']);
    final googleStatus =
        results['pingGoogle']?['status'] as real_state.TestStatus? ??
            real_state.TestStatus.pending;
    final googleResult = _safeResultString(results['pingGoogle']?['result']);
    final cloudflareStatus =
        results['pingCloudflare']?['status'] as real_state.TestStatus? ??
            real_state.TestStatus.pending;
    final cloudflareResult =
        _safeResultString(results['pingCloudflare']?['result']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Jornada da Conexão',
          icon: Icons.route_rounded,
          color: DiagnosticTheme.cyan,
          hasData: wifiStatus != real_state.TestStatus.pending,
        ),
        HoloCard(
          isScanning: wifiStatus == real_state.TestStatus.running ||
              gatewayStatus == real_state.TestStatus.running,
          accent: DiagnosticTheme.cyan,
          child: Column(
            children: [
              _buildJourneyStep(
                icon: Icons.phone_android_rounded,
                title: 'Você (Dispositivo)',
                status: wifiStatus,
                details: [
                  (
                    'Sinal',
                    DiagnosticUtils.parseResultLine(
                      wifiResult,
                      'Força do Sinal:',
                    ),
                  ),
                  (
                    'SSID',
                    DiagnosticUtils.parseResultLine(wifiResult, 'SSID:'),
                  ),
                ],
              ),
              _buildJourneyConnector(wifiStatus),
              _buildJourneyStep(
                icon: Icons.router_rounded,
                title: 'Seu Roteador',
                status: gatewayStatus,
                details: [
                  (
                    'IP',
                    DiagnosticUtils.parseResultLine(
                      wifiResult,
                      'Gateway (Roteador):',
                    ),
                  ),
                  (
                    'Latência',
                    DiagnosticUtils.parseResultLine(gatewayResult, 'Latência:'),
                  ),
                  (
                    'Jitter',
                    DiagnosticUtils.parseResultLine(gatewayResult, 'Jitter:'),
                  ),
                ],
              ),
              _buildJourneyConnector(gatewayStatus),
              _buildJourneyStep(
                icon: Icons.cloud_queue_rounded,
                title: 'Nossa Rede',
                status: ipStatus,
                details: [
                  ('IPv4', DiagnosticUtils.parseResultLine(ipResult, 'IPv4:')),
                  ('IPv6', DiagnosticUtils.parseResultLine(ipResult, 'IPv6:')),
                ],
              ),
              _buildJourneyConnector(ipStatus),
              _buildJourneyStep(
                icon: Icons.dns_rounded,
                title: 'Internet (DNS)',
                status: (googleStatus == real_state.TestStatus.success ||
                        cloudflareStatus == real_state.TestStatus.success)
                    ? real_state.TestStatus.success
                    : googleStatus,
                details: [
                  (
                    'Google',
                    (DiagnosticUtils.parseResultLine(
                        googleResult, 'Latência:')),
                  ),
                  (
                    'Cloudflare',
                    (DiagnosticUtils.parseResultLine(
                        cloudflareResult, 'Latência:')),
                  ),
                ],
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyStep({
    required IconData icon,
    required String title,
    required real_state.TestStatus status,
    required List<(String, String)> details,
    bool isLast = false,
  }) {
    final color = _getStatusColor(status);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(100)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (status == real_state.TestStatus.running)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    else
                      Icon(
                        status == real_state.TestStatus.success
                            ? Icons.check_circle
                            : status == real_state.TestStatus.error
                                ? Icons.error
                                : Icons.schedule,
                        color: color,
                        size: 14,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: details
                      .map(
                        (d) => Text(
                          '${d.$1}: ${d.$2}',
                          style: const TextStyle(
                            color: DiagnosticTheme.textDim,
                            fontSize: 11,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyConnector(real_state.TestStatus status) {
    return Padding(
      padding: const EdgeInsets.only(left: 17, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 20,
            color: _getStatusColor(status).withAlpha(60),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED WIFI DETAILS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWifiDetailsSection() {
    if (realState == null) return const SizedBox.shrink();

    final wifiRes = realState!.testResultsDisplay['wifiInfo']?['result'];
    final status = realState!.testResultsDisplay['wifiInfo']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;

    if (status == real_state.TestStatus.pending) return const SizedBox.shrink();

    String bssid = '---';
    String ip = '---';
    String dns = '---';
    String freq = '---';
    String channel = '---';
    String security = '---';

    if (wifiRes is Map) {
      bssid = wifiRes['bssid']?.toString() ?? '---';
      ip = wifiRes['ip']?.toString() ?? '---';
      dns = wifiRes['dns']?.toString() ?? '---';
      freq = wifiRes['frequency']?.toString() ?? '---';
      channel = wifiRes['channel']?.toString() ?? '---';
      security = wifiRes['security']?.toString() ?? '---';
    } else if (wifiRes is String) {
      bssid = DiagnosticUtils.parseResultLine(wifiRes, 'BSSID:');
      ip = DiagnosticUtils.parseResultLine(wifiRes, 'IP Dispositivo:');
      dns = DiagnosticUtils.parseResultLine(wifiRes, 'Servidores DNS:');
      freq = DiagnosticUtils.parseResultLine(wifiRes, 'Frequência:');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Detalhes WiFi',
          icon: Icons.info_outline_rounded,
          color: DiagnosticTheme.pink,
          hasData: wifiRes != null,
        ),
        HoloCard(
          isScanning: status == real_state.TestStatus.running,
          accent: DiagnosticTheme.pink,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: DiagnosticDataRow(
                    icon: Icons.router,
                    label: 'BSSID',
                    value: bssid,
                    color: DiagnosticTheme.pink,
                  )),
                  Expanded(
                      child: DiagnosticDataRow(
                    icon: Icons.computer,
                    label: 'IP Local',
                    value: ip,
                    color: DiagnosticTheme.pink,
                  )),
                ],
              ),
              DiagnosticDataRow(
                icon: Icons.dns,
                label: 'DNS',
                value: dns,
                color: DiagnosticTheme.pink,
              ),
              Row(
                children: [
                  Expanded(
                      child: DiagnosticDataRow(
                    icon: Icons.signal_wifi_4_bar,
                    label: 'Frequência',
                    value: freq,
                    color: DiagnosticTheme.pink,
                  )),
                  Expanded(
                      child: DiagnosticDataRow(
                    icon: Icons.tune,
                    label: 'Canal',
                    value: channel,
                    color: DiagnosticTheme.pink,
                  )),
                ],
              ),
              DiagnosticDataRow(
                icon: Icons.security,
                label: 'Segurança',
                value: security,
                color: DiagnosticTheme.pink,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED LAN SCAN SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLanDetailsSection() {
    if (realState == null) return const SizedBox.shrink();

    final lanResult =
        _safeResultString(realState!.testResultsDisplay['lanScan']?['result']);
    final status = realState!.testResultsDisplay['lanScan']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;

    if (status == real_state.TestStatus.pending) return const SizedBox.shrink();

    // Parse device count
    final deviceCount = DiagnosticUtils.parseResultLine(
      lanResult,
      'Dispositivos encontrados:',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Dispositivos na Rede',
          icon: Icons.devices_rounded,
          color: DiagnosticTheme.purple,
          hasData: lanResult != null,
        ),
        HoloCard(
          isScanning: status == real_state.TestStatus.running,
          accent: DiagnosticTheme.purple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.devices_other,
                    color: DiagnosticTheme.purple,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceCount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'dispositivos encontrados',
                        style: TextStyle(
                          color: DiagnosticTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (lanResult != null && lanResult.contains('sub-rede')) ...[
                const SizedBox(height: 12),
                Text(
                  lanResult
                      .split('\n')
                      .lastWhere(
                        (l) => l.contains('sub-rede'),
                        orElse: () => '',
                      )
                      .replaceAll('(', '')
                      .replaceAll(')', ''),
                  style: const TextStyle(
                    color: DiagnosticTheme.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED DEVICE INFO SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDeviceDetailsSection() {
    if (realState == null) return const SizedBox.shrink();

    final deviceResult = _safeResultString(
        realState!.testResultsDisplay['deviceInfo']?['result']);
    final status = realState!.testResultsDisplay['deviceInfo']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;

    if (status == real_state.TestStatus.pending) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Info do Dispositivo',
          icon: Icons.smartphone_rounded,
          color: DiagnosticTheme.gold,
          hasData: deviceResult != null,
        ),
        HoloCard(
          isScanning: status == real_state.TestStatus.running,
          accent: DiagnosticTheme.gold,
          child: Column(
            children: [
              DiagnosticDataRow(
                icon: Icons.wifi,
                label: 'Conexão',
                value: DiagnosticUtils.parseResultLine(
                  deviceResult,
                  'Conexão:',
                ),
                color: DiagnosticTheme.gold,
              ),
              DiagnosticDataRow(
                icon: Icons.android,
                label: 'Sistema',
                value: DiagnosticUtils.parseResultLine(
                  deviceResult,
                  'Versão OS:',
                ),
                color: DiagnosticTheme.gold,
              ),
              DiagnosticDataRow(
                icon: Icons.phone_android,
                label: 'Dispositivo',
                value: DiagnosticUtils.parseResultLine(
                  deviceResult,
                  'Dispositivo:',
                ),
                color: DiagnosticTheme.gold,
              ),
              DiagnosticDataRow(
                icon: Icons.info_outline,
                label: 'App',
                value: DiagnosticUtils.parseResultLine(
                  deviceResult,
                  'Versão do App:',
                ),
                color: DiagnosticTheme.gold,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED ONU/FIBRA SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOnuDetailsSection() {
    if (realState == null) return const SizedBox.shrink();

    final onuResult = realState!.testResultsDisplay['onuInfo']?['result'];
    final status = realState!.testResultsDisplay['onuInfo']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;

    if (status == real_state.TestStatus.pending) return const SizedBox.shrink();

    String rxPower = '---';
    String txPower = '---';
    String temperature = '---';
    String onuModel = '---';
    String voltage = '---';
    String bias = '---';

    if (onuResult is Map) {
      rxPower = onuResult['rxPower']?.toString() ?? '---';
      txPower = onuResult['txPower']?.toString() ?? '---';
      temperature = onuResult['temperature']?.toString() ?? '---';
      onuModel = onuResult['model']?.toString() ?? '---';
      voltage = onuResult['voltage']?.toString() ?? '---';
      bias = onuResult['biasCurrent']?.toString() ?? '---';
    } else if (status == real_state.TestStatus.error || onuResult is String) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'ONU / Fibra Óptica',
            icon: Icons.router,
            color: DiagnosticTheme.red,
            hasData: false,
          ),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: DiagnosticTheme.red.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DiagnosticTheme.red.withAlpha(50)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: DiagnosticTheme.red,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Erro na leitura da ONU",
                  style: TextStyle(
                    color: DiagnosticTheme.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  onuResult is String
                      ? onuResult
                      : "Verifique a conexão com o servidor.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DiagnosticTheme.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Color rxColor = DiagnosticTheme.green;
    final rxValue = double.tryParse(rxPower) ?? 0;
    if (rxValue < -25) {
      rxColor = DiagnosticTheme.red;
    } else if (rxValue < -20) {
      rxColor = DiagnosticTheme.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'ONU / Fibra Óptica',
          icon: Icons.cable_rounded,
          color: DiagnosticTheme.cyan,
          hasData: status == real_state.TestStatus.success,
        ),
        HoloCard(
          isScanning: status == real_state.TestStatus.running,
          accent: DiagnosticTheme.cyan,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildOnuStat('Rx Power', '$rxPower dBm', rxColor),
                  ),
                  Expanded(
                    child: _buildOnuStat(
                      'Tx Power',
                      '$txPower dBm',
                      DiagnosticTheme.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildOnuStat(
                      'Temperatura',
                      '$temperature°C',
                      DiagnosticTheme.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildOnuStat(
                      'Modelo',
                      onuModel,
                      DiagnosticTheme.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildOnuStat(
                      'Voltagem',
                      '$voltage V',
                      DiagnosticTheme.green,
                    ),
                  ),
                  Expanded(
                    child: _buildOnuStat(
                      'Bias Current',
                      '$bias mA',
                      DiagnosticTheme.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOnuStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(color: DiagnosticTheme.textDim, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN PAGE - Controller
// ═══════════════════════════════════════════════════════════════════════════
