/// "Your Wi-Fi is set to Public" (TASK-PL1): Windows Firewall blocks
/// incoming connections on public networks, so sharing doesn't start there.
class PublicNetworkException implements Exception {
  const new();

  @override
  String toString() => 'PublicNetworkException: network profile is Public';
}

/// PL1: what sharing on Windows checks before the server binds, UI-agnostic.
/// - The network profile: Public → [PublicNetworkException] (shown instead
///   of the QR).
/// - The first bind triggers the Windows Firewall prompt: [explainFirewall]
///   (set by the UI) says "Allow on private networks only" first, once.
class WindowsShareCheck {
  new({
    required this._isPublic,
    required this._firewallExplained,
    required this._markFirewallExplained,
  });

  final Future<bool> Function() _isPublic;
  final Future<bool> Function() _firewallExplained;
  final Future<void> Function() _markFirewallExplained;

  /// Set by the share screen; completes when the explainer is dismissed.
  Future<void> Function()? explainFirewall;

  /// Throws [PublicNetworkException] on a Public network; shows the
  /// firewall explainer before the first bind. Channel errors propagate.
  Future<void> beforeBind() async {
    if (await _isPublic()) throw const PublicNetworkException();
    if (await _firewallExplained()) return;
    final explain = explainFirewall;
    if (explain == null) return; // asked again the next time
    await explain();
    await _markFirewallExplained();
  }
}
