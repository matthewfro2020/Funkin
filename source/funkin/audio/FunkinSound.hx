package funkin.audio;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.audio.waveform.WaveformData;
import funkin.audio.waveform.WaveformDataParser;
import funkin.data.song.SongData.SongMusicData;
import funkin.data.song.SongRegistry;
import funkin.util.tools.ICloneable;
import funkin.util.flixel.sound.FlxPartialSound;
import funkin.Paths.PathsFunction;
import lime.app.Promise;
import lime.media.AudioSource;
import lime.media.AudioBuffer;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundMixer;

/**
 * A FlxSound with extra features for FNF.
 */
@:nullSafety
class FunkinSound extends FlxSound implements ICloneable<FunkinSound>
{
  static final MAX_VOLUME:Float = 1.0;

  public static var onVolumeChanged(get, never):FlxTypedSignal<Float->Void>;
  static var _onVolumeChanged:Null<FlxTypedSignal<Float->Void>> = null;

  static function get_onVolumeChanged():FlxTypedSignal<Float->Void>
  {
    if (_onVolumeChanged == null)
    {
      _onVolumeChanged = new FlxTypedSignal<Float->Void>();
      FlxG.sound.onVolumeChange.add((v) -> _onVolumeChanged.dispatch(v));
    }
    return _onVolumeChanged;
  }

  static var pool(default, null):FlxTypedGroup<FunkinSound> = new FlxTypedGroup<FunkinSound>();

  public var muted(default, set):Bool = false;
  function set_muted(v:Bool):Bool { muted = v; updateTransform(); return v; }

  override function set_volume(v:Float):Float
  {
    _volume = v.clamp(0.0, MAX_VOLUME);
    updateTransform();
    return _volume;
  }

  public var paused(get, never):Bool;
  function get_paused() return _paused;

  public var isPlaying(get, never):Bool;
  function get_isPlaying() return playing || _shouldPlay;

  public var waveformData(get, never):WaveformData;
  var _waveformData:Null<WaveformData> = null;
  function get_waveformData():WaveformData
  {
    if (_waveformData == null)
    {
      _waveformData = WaveformDataParser.interpretFlxSound(this);
      if (_waveformData == null) throw 'Could not interpret waveform data!';
    }
    return _waveformData;
  }

  public var important:Bool = false;
  var _shouldPlay:Bool = false;
  var _label:String = "unknown";
  var _lostFocus:Bool = false;

  public function new() super();

  override function update(elapsed:Float)
  {
    if (!playing && !_shouldPlay) return;

    if (_time < 0)
    {
      _time += elapsed * Constants.MS_PER_SEC;
      if (_time >= 0)
      {
        super.play();
        _shouldPlay = false;
      }
    }
    else
    {
      super.update(elapsed);
      @:privateAccess if (important && _channel != null && !SoundMixer.__soundChannels.contains(_channel))
        SoundMixer.__soundChannels.push(_channel);
    }
  }

  override function play(forceRestart:Bool = false, startTime:Float = 0, ?endTime:Float):FunkinSound
  {
    if (!exists) return this;
    if (forceRestart) cleanup(false, true); else if (playing) return this;

    if (startTime < 0)
    {
      active = true; _shouldPlay = true; _time = startTime; this.endTime = endTime;
    }
    else
    {
      if (_paused) resume(); else startSound(startTime);
      this.endTime = endTime;
    }
    return this;
  }

  override function resume():FunkinSound
  {
    if (_time < 0) { _shouldPlay = true; _paused = false; active = true; }
    else super.resume();
    return this;
  }

  @:allow(flixel.sound.FlxSoundGroup)
  override function updateTransform():Void
  {
    if (_transform != null)
    {
      _transform.volume = ((FlxG.sound.muted || muted) ? 0 : 1) * FlxG.sound.volume
        * (group != null ? group.volume : 1) * _volume * _volumeAdjust;
    }
    if (_channel != null) _channel.soundTransform = _transform;
  }

  public function clone():FunkinSound
  {
    var snd = new FunkinSound();
    @:privateAccess {
      var buf:AudioBuffer = this._sound.__buffer;
      snd._sound = new Sound();
      snd._sound.loadFromBuffer(buf);
      snd._waveformData = this._waveformData;
    }
    snd.init(this.looped, this.autoDestroy, this.onComplete);
    return snd;
  }

  override function startSound(startTime:Float)
  {
    if (!important) { super.startSound(startTime); return; }
    _time = startTime; _paused = false;
    if (_sound == null) return;

    var pan = (_transform.pan).clamp(-1, 1);
    var vol = (_transform.volume).clamp(0, MAX_VOLUME);

    var audioSource = new AudioSource(_sound.__buffer);
    audioSource.offset = Std.int(startTime);
    audioSource.gain = vol;
    audioSource.position.x = pan;

    _channel = new SoundChannel(audioSource, _transform);
    _channel.addEventListener(Event.SOUND_COMPLETE, stopped);
    pitch = _pitch; active = true;
  }

  static function construct():FunkinSound
  {
    var snd = new FunkinSound();
    pool.add(snd);
    FlxG.sound.list.add(snd);
    return snd;
  }

  override function toString():String return 'FunkinSound($_label)';
}
