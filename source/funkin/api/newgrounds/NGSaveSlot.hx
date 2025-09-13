package funkin.api.newgrounds;

#if FEATURE_NEWGROUNDS
import io.newgrounds.utils.SaveSlotList;
import io.newgrounds.objects.SaveSlot;
import io.newgrounds.Call.CallError;
import io.newgrounds.objects.events.Outcome;
import funkin.save.Save;

@:nullSafety
@:access(funkin.save.Save)
class NGfunkin.save.SaveSlot
{
  public static var instance(get, never):NGfunkin.save.SaveSlot;
  static var _instance:Null<NGfunkin.save.SaveSlot> = null;

  static function get_instance():NGfunkin.save.SaveSlot
  {
    if (_instance == null)
    {
      return loadInstance();
    }
    return _instance;
  }

  public static function loadInstance():NGfunkin.save.SaveSlot
  {
    var loadedfunkin.save.Save:NGfunkin.save.SaveSlot = loadSlot(funkin.save.Save.BASE_SAVE_SLOT);
    if (_instance == null) _instance = loadedfunkin.save.Save;

    return loadedfunkin.save.Save;
  }

  static function loadSlot(slot:Int):NGfunkin.save.SaveSlot
  {
    trace('[NEWGROUNDS] Getting save slot from ID $slot');

    var saveSlot:Null<funkin.save.SaveSlot> = NewgroundsClient.instance.saveSlots?.getById(slot);

    var saveSlotObj:NGfunkin.save.SaveSlot = new NGfunkin.save.SaveSlot(saveSlot);
    return saveSlotObj;
  }

  public var ngfunkin.save.SaveSlot:Null<funkin.save.SaveSlot> = null;

  public function new(?ngfunkin.save.SaveSlot:Null<funkin.save.SaveSlot>)
  {
    this.ngfunkin.save.SaveSlot = ngfunkin.save.SaveSlot;

    #if FLX_DEBUG
    FlxG.console.registerClass(NGfunkin.save.SaveSlot);
    FlxG.console.registerClass(funkin.save.Save);
    #end
  }

  /**
   * funkin.save.Saves `data` to the newgrounds save slot.
   * @param data The raw save data.
   */
  public function save(data:Rawfunkin.save.SaveData):Void
  {
    var encodedData:String = haxe.Serializer.run(data);

    try
    {
      ngfunkin.save.SaveSlot?.save(encodedData, function(outcome:Outcome<CallError>) {
        switch (outcome)
        {
          case SUCCESS:
            trace('[NEWGROUNDS] Successfully saved save data to save slot!');
          case FAIL(error):
            trace('[NEWGROUNDS] Failed to save data to save slot!');
            trace(error);
        }
      });
    }
    catch (error:String)
    {
      trace('[NEWGROUNDS] Failed to save data to save slot!');
      trace(error);
    }
  }

  public function load(?onComplete:Null<Dynamic->Void>, ?onError:Null<CallError->Void>):Void
  {
    try
    {
      ngfunkin.save.SaveSlot?.load(function(outcome:funkin.save.SaveSlotOutcome):Void {
        switch (outcome)
        {
          case SUCCESS(value):
            trace('[NEWGROUNDS] Loaded save slot with the ID of ${ngfunkin.save.SaveSlot?.id}!');
            #if FEATURE_DEBUG_FUNCTIONS
            trace('funkin.save.Save Slot Data:');
            trace(value);
            #end

            if (onComplete != null && value != null)
            {
              var decodedData:Dynamic = haxe.Unserializer.run(value);
              onComplete(decodedData);
            }
          case FAIL(error):
            trace('[NEWGROUNDS] Failed to load save slot with the ID of ${ngfunkin.save.SaveSlot?.id}!');
            trace(error);

            if (onError != null)
            {
              onError(error);
            }
        }
      });
    }
    catch (error:String)
    {
      trace('[NEWGROUNDS] Failed to load save slot with the ID of ${ngfunkin.save.SaveSlot?.id}!');
      trace(error);

      if (onError != null)
      {
        onError(RESPONSE({message: error, code: 500}));
      }
    }
  }

  public function clear():Void
  {
    try
    {
      ngfunkin.save.SaveSlot?.clear(function(outcome:Outcome<CallError>) {
        switch (outcome)
        {
          case SUCCESS:
            trace('[NEWGROUNDS] Successfully cleared save slot!');
          case FAIL(error):
            trace('[NEWGROUNDS] Failed to clear save slot!');
            trace(error);
        }
      });
    }
    catch (error:String)
    {
      trace('[NEWGROUNDS] Failed to clear save slot!');
      trace(error);
    }
  }

  public function checkSlot():Void
  {
    trace('[NEWGROUNDS] Checking save slot with the ID of ${ngfunkin.save.SaveSlot?.id}...');

    trace('  Is null? ${ngfunkin.save.SaveSlot == null}');
    trace('  Is empty? ${ngfunkin.save.SaveSlot?.isEmpty() ?? false}');
  }
}
#end