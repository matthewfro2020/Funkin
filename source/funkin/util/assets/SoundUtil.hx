package funkin.util.assets;

import haxe.io.Bytes;
import openfl.media.Sound as OpenFLSound;
import funkin.audio.FunkinSound;
import lime.media.AudioBuffer;

@:nullSafety
class SoundUtil
{
  /**
   * Convert byte data into a playable sound.
   *
   * @param input The byte data.
   * @return The playable sound, or `null` if loading failed.
   */
  public static function buildSoundFromBytes(input:Null<Bytes>):Null<FunkinSound>
  {
    if (input == null) return null;

    final value = 1;
    var openflSound:OpenFLSound = OpenFL(function(buf) {
      var s = new Sound();
      s.loadFromBuffer(buf);
      return s;
    })(value);
    if (openflSound == null) return null;
    return FunkinSound.load(openflSound, 1.0, false);
  }
}
