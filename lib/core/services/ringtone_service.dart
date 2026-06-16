import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service de sonnerie pour les appels entrants.
///
/// Génère un fichier WAV sinusoïdal (bip répété) au premier lancement,
/// puis le joue en boucle via [AudioPlayer]. Le fichier est stocké
/// dans le répertoire temporaire de l'app.
///
/// Usage :
/// ```dart
/// final service = RingtoneService();
/// await service.startRinging();
/// // … écran d'appel entrant affiché …
/// await service.stopRinging();
/// ```
class RingtoneService {
  AudioPlayer? _player;
  bool _isRinging = false;

  // ── Paramètres du son ──────────────────────────────────────────────────

  /// Fréquence du bip principal (Hz).
  static const int _bipFrequency = 800;

  /// Durée d'un bip (ms).
  static const int _bipDurationMs = 400;

  /// Silence entre deux bips (ms).
  static const int _silenceDurationMs = 600;

  /// Fréquence d'échantillonnage.
  static const int _sampleRate = 44100;

  /// Amplitude (0.0 → 1.0).
  static const double _amplitude = 0.7;

  // ── API publique ───────────────────────────────────────────────────────

  /// Démarre la sonnerie en boucle.
  Future<void> startRinging() async {
    if (_isRinging) return;

    final path = await _ensureRingtoneFile();

    _player = AudioPlayer();
    await _player!.setReleaseMode(ReleaseMode.loop);
    await _player!.play(DeviceFileSource(path));

    _isRinging = true;
  }

  /// Arrête la sonnerie et libère les ressources.
  Future<void> stopRinging() async {
    if (!_isRinging) return;

    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (_) {
      // ignore
    } finally {
      _player = null;
      _isRinging = false;
    }
  }

  bool get isRinging => _isRinging;

  // ── Génération du fichier WAV ──────────────────────────────────────────

  /// Retourne le chemin du fichier ringtone, en le générant si nécessaire.
  Future<String> _ensureRingtoneFile() async {
    final dir = Directory.systemTemp;
    final path = '${dir.path}/fulbe_ringtone.wav';
    final file = File(path);

    if (!await file.exists()) {
      final wavBytes = _generateRingtoneWav();
      await file.writeAsBytes(wavBytes);
      debugPrint('[RingtoneService] Fichier WAV généré : $path');
    }

    return path;
  }

  /// Génère un WAV contenant un motif de bip répété.
  ///
  /// Format : PCM 16-bit signed, mono, 44100 Hz.
  /// Motif : [_bipDurationMs] ms de sinusoïde à [_bipFrequency] Hz,
  ///         puis [_silenceDurationMs] ms de silence.
  /// Le motif est répété pour atteindre ~6 secondes de sonnerie.
  Uint8List _generateRingtoneWav() {
    // Nombre d'échantillons pour un cycle bip+silence
    final bipSamples = (_sampleRate * _bipDurationMs / 1000).round();
    final silenceSamples = (_sampleRate * _silenceDurationMs / 1000).round();
    final cycleSamples = bipSamples + silenceSamples;

    // On génère plusieurs cycles (~6 secondes)
    const targetDurationMs = 6000;
    final totalSamples = (_sampleRate * targetDurationMs / 1000).round();
    final cycles = (totalSamples / cycleSamples).ceil();
    final totalDataSamples = cycles * cycleSamples;

    // Buffer PCM 16-bit
    final pcmData = Int16List(totalDataSamples);

    for (var i = 0; i < totalDataSamples; i++) {
      final posInCycle = i % cycleSamples;
      if (posInCycle < bipSamples) {
        // Bip sinusoïdal avec enveloppe douce (attaque/décroissance)
        final t = posInCycle / _sampleRate;
        final envelope = min(1.0, min(
          posInCycle / (_sampleRate * 0.01),         // attaque 10ms
          (bipSamples - posInCycle) / (_sampleRate * 0.01), // décroissance 10ms
        ));
        final sample = (sin(2 * pi * _bipFrequency * t) * _amplitude * envelope * 32767).round();
        pcmData[i] = sample.clamp(-32768, 32767);
      } else {
        // Silence
        pcmData[i] = 0;
      }
    }

    // Construction du header WAV (44 octets) + données PCM
    final dataSize = totalDataSamples * 2; // 2 bytes par échantillon (16-bit)
    final fileSize = 36 + dataSize;
    final header = ByteData(44);

    // RIFF header
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, fileSize, Endian.little); // File size - 8
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'

    // fmt chunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little);       // Subchunk1 size (PCM)
    header.setUint16(20, 1, Endian.little);         // Audio format (PCM)
    header.setUint16(22, 1, Endian.little);         // Num channels (mono)
    header.setUint32(24, _sampleRate, Endian.little); // Sample rate
    header.setUint32(28, _sampleRate * 2, Endian.little); // Byte rate
    header.setUint16(32, 2, Endian.little);         // Block align
    header.setUint16(34, 16, Endian.little);        // Bits per sample

    // data chunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataSize, Endian.little);  // Subchunk2 size

    // Combine header + PCM data
    final result = Uint8List(44 + dataSize);
    result.setRange(0, 44, Uint8List.view(header.buffer, 0, 44));
    result.setRange(44, 44 + dataSize, Uint8List.view(pcmData.buffer, 0, dataSize));

    return result;
  }
}
