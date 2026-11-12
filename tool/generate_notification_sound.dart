import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int _sampleRate = 44100;
const int _channelCount = 1;
const int _bitsPerSample = 16;

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/generate_notification_sound.dart <output.wav>',
    );
    exitCode = 64;
    return;
  }

  final samples = _buildChime();
  final bytesPerSample = _bitsPerSample ~/ 8;
  final dataLength = samples.length * bytesPerSample;
  final wave = ByteData(44 + dataLength);

  _writeFourCc(wave, 0, 'RIFF');
  wave.setUint32(4, 36 + dataLength, Endian.little);
  _writeFourCc(wave, 8, 'WAVE');
  _writeFourCc(wave, 12, 'fmt ');
  wave.setUint32(16, 16, Endian.little);
  wave.setUint16(20, 1, Endian.little);
  wave.setUint16(22, _channelCount, Endian.little);
  wave.setUint32(24, _sampleRate, Endian.little);
  wave.setUint32(
    28,
    _sampleRate * _channelCount * bytesPerSample,
    Endian.little,
  );
  wave.setUint16(32, _channelCount * bytesPerSample, Endian.little);
  wave.setUint16(34, _bitsPerSample, Endian.little);
  _writeFourCc(wave, 36, 'data');
  wave.setUint32(40, dataLength, Endian.little);

  for (var index = 0; index < samples.length; index++) {
    wave.setInt16(44 + index * bytesPerSample, samples[index], Endian.little);
  }

  final output = File(arguments.single);
  output.parent.createSync(recursive: true);
  output.writeAsBytesSync(wave.buffer.asUint8List(), flush: true);
}

Int16List _buildChime() {
  const durationSeconds = 0.72;
  final sampleCount = (_sampleRate * durationSeconds).round();
  final samples = Int16List(sampleCount);

  for (var index = 0; index < sampleCount; index++) {
    final time = index / _sampleRate;
    final isSecondNote = time >= 0.30;
    final noteStart = isSecondNote ? 0.30 : 0.0;
    final noteDuration = isSecondNote ? 0.42 : 0.27;
    final noteTime = time - noteStart;

    if (noteTime < 0 || noteTime > noteDuration) {
      continue;
    }

    final frequency = isSecondNote ? 1174.66 : 880.0;
    final attack = math.min(1.0, noteTime / 0.025);
    final release = math.min(1.0, (noteDuration - noteTime) / 0.14);
    final envelope = attack * release;
    final fundamental = math.sin(2 * math.pi * frequency * noteTime);
    final harmonic = math.sin(4 * math.pi * frequency * noteTime);
    final sample = envelope * (0.82 * fundamental + 0.18 * harmonic);

    samples[index] = (sample * 0.34 * 32767).round();
  }

  return samples;
}

void _writeFourCc(ByteData data, int offset, String value) {
  for (var index = 0; index < 4; index++) {
    data.setUint8(offset + index, value.codeUnitAt(index));
  }
}
