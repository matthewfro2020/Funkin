package funkin.save.migrator;

import funkin.save.Save;
import funkin.save.migrator.Rawfunkin.save.SaveData_v1_0_0;
import thx.semver.Version;
import funkin.util.VersionUtil;

@:nullSafety
class funkin.save.SaveDataMigrator
{
  /**
   * Migrate from one 2.x version to another.
   */
  public static function migrate(inputData:Dynamic):funkin.save.Save
  {
    var version:Null<thx.semver.Version> = VersionUtil.parseVersion(inputData?.version ?? null);

    if (version == null)
    {
      trace('[SAVE] No version found in save data! Returning blank data.');
      trace(inputData);
      return new funkin.save.Save(funkin.save.Save.getDefault());
    }
    else
    {
      // Sometimes the Haxe serializer has issues with the version so we fix it here.
      version = VersionUtil.repairVersion(version);
      if (VersionUtil.validateVersion(version, funkin.save.Save.SAVE_DATA_VERSION_RULE))
      {
        // Import the structured data.
        var saveDataWithDefaults:Rawfunkin.save.SaveData = cast thx.Objects.deepCombine(funkin.save.Save.getDefault(), inputData);
        var save:funkin.save.Save = new funkin.save.Save(saveDataWithDefaults);
        return save;
      }
      else if (VersionUtil.validateVersion(version, "2.0.x"))
      {
        return migrate_v2_0_0(inputData);
      }
      else
      {
        var message:String = 'Error migrating save data, expected ${funkin.save.Save.SAVE_DATA_VERSION}.';
        var slot:Int = funkin.save.Save.archiveBadfunkin.save.SaveData(inputData);
        var fullMessage:String = 'An error occurred migrating your save data.\n${message}\nInvalid data has been moved to save slot ${slot}.';
        funkin.util.WindowUtil.showError("funkin.save.Save Data Failure", fullMessage);
        return new funkin.save.Save(funkin.save.Save.getDefault());
      }
    }
  }

  static function migrate_v2_0_0(inputData:Dynamic):funkin.save.Save
  {
    // Import the structured data.
    var saveDataWithDefaults:Rawfunkin.save.SaveData = cast thx.Objects.deepCombine(funkin.save.Save.getDefault(), inputData);

    // Reset these values to valid ones.
    saveDataWithDefaults.optionsChartEditor.chartEditorLiveInputStyle = funkin.ui.debug.charting.ChartEditorState.ChartEditorLiveInputStyle.None;
    saveDataWithDefaults.optionsChartEditor.theme = funkin.ui.debug.charting.ChartEditorState.ChartEditorTheme.Light;
    saveDataWithDefaults.optionsStageEditor.theme = funkin.ui.debug.stageeditor.StageEditorState.StageEditorTheme.Light;

    var save:funkin.save.Save = new funkin.save.Save(saveDataWithDefaults);
    return save;
  }

  /**
   * Migrate from 1.x to the latest version.
   */
  public static function migrateFromLegacy(inputData:Dynamic):funkin.save.Save
  {
    var inputfunkin.save.SaveData:Rawfunkin.save.SaveData_v1_0_0 = cast inputData;

    var result:funkin.save.Save = new funkin.save.Save(funkin.save.Save.getDefault());

    result.volume = inputfunkin.save.SaveData.volume;
    result.mute = inputfunkin.save.SaveData.mute;

    result.ngSessionId = inputfunkin.save.SaveData.sessionId;

    // TODO: Port over the save data from the legacy save data format.
    migrateLegacyScores(result, inputfunkin.save.SaveData);

    migrateLegacyControls(result, inputfunkin.save.SaveData);

    return result;
  }

  static function migrateLegacyScores(result:funkin.save.Save, inputfunkin.save.SaveData:Rawfunkin.save.SaveData_v1_0_0):Void
  {
    if (inputfunkin.save.SaveData.songCompletion == null)
    {
      inputfunkin.save.SaveData.songCompletion = [];
    }

    if (inputfunkin.save.SaveData.songScores == null)
    {
      inputfunkin.save.SaveData.songScores = [];
    }

    migrateLegacyLevelScore(result, inputfunkin.save.SaveData, 'week0');
    migrateLegacyLevelScore(result, inputfunkin.save.SaveData, 'week1');
    migrateLegacyLevelScore(result, inputfunkin.save.SaveData, 'week2');
    migrateLegacyLevelScore(result, inputfunkin.save.SaveData, 'week3');
    migrateLegacyLevelScore(result, inputfunkin.save.SaveData, 'week4');
    migrateLegacyLevelScore(result, inputfunkin.save.SaveData, 'week5');
    migrateLegacyLevelScore(result, inputfunkin.save.SaveData, 'week6');
    migrateLegacyLevelScore(result, inputfunkin.save.SaveData, 'week7');

    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['tutorial', 'Tutorial']);

    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['bopeebo', 'Bopeebo']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['fresh', 'Fresh']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['dadbattle', 'Dadbattle']);

    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['monster', 'Monster']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['south', 'South']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['spookeez', 'Spookeez']);

    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['pico', 'Pico']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['philly-nice', 'Philly', 'philly', 'Philly-Nice']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['blammed', 'Blammed']);

    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['satin-panties', 'Satin-Panties']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['high', 'High']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['milf', 'Milf', 'MILF']);

    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['cocoa', 'Cocoa']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['eggnog', 'Eggnog']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['winter-horrorland', 'Winter-Horrorland']);

    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['senpai', 'Senpai']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['roses', 'Roses']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['thorns', 'Thorns']);

    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['ugh', 'Ugh']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['guns', 'Guns']);
    migrateLegacySongScore(result, inputfunkin.save.SaveData, ['stress', 'Stress']);
  }

  static function migrateLegacyLevelScore(result:funkin.save.Save, inputfunkin.save.SaveData:Rawfunkin.save.SaveData_v1_0_0, levelId:String):Void
  {
    var scoreDataEasy:funkin.save.SaveScoreData =
      {
        score: inputfunkin.save.SaveData.songScores.get('${levelId}-easy') ?? 0,
        // accuracy: inputfunkin.save.SaveData.songCompletion.get('${levelId}-easy') ?? 0.0,
        tallies:
          {
            sick: 0,
            good: 0,
            bad: 0,
            shit: 0,
            missed: 0,
            combo: 0,
            maxCombo: 0,
            totalNotesHit: 0,
            totalNotes: 0,
          }
      };
    result.setLevelScore(levelId, 'easy', scoreDataEasy);

    var scoreDataNormal:funkin.save.SaveScoreData =
      {
        score: inputfunkin.save.SaveData.songScores.get('${levelId}') ?? 0,
        // accuracy: inputfunkin.save.SaveData.songCompletion.get('${levelId}') ?? 0.0,
        tallies:
          {
            sick: 0,
            good: 0,
            bad: 0,
            shit: 0,
            missed: 0,
            combo: 0,
            maxCombo: 0,
            totalNotesHit: 0,
            totalNotes: 0,
          }
      };
    result.setLevelScore(levelId, 'normal', scoreDataNormal);

    var scoreDataHard:funkin.save.SaveScoreData =
      {
        score: inputfunkin.save.SaveData.songScores.get('${levelId}-hard') ?? 0,
        // accuracy: inputfunkin.save.SaveData.songCompletion.get('${levelId}-hard') ?? 0.0,
        tallies:
          {
            sick: 0,
            good: 0,
            bad: 0,
            shit: 0,
            missed: 0,
            combo: 0,
            maxCombo: 0,
            totalNotesHit: 0,
            totalNotes: 0,
          }
      };
    result.setLevelScore(levelId, 'hard', scoreDataHard);
  }

  static function migrateLegacySongScore(result:funkin.save.Save, inputfunkin.save.SaveData:Rawfunkin.save.SaveData_v1_0_0, songIds:Array<String>):Void
  {
    var scoreDataEasy:funkin.save.SaveScoreData =
      {
        score: 0,
        tallies:
          {
            sick: 0,
            good: 0,
            bad: 0,
            shit: 0,
            missed: 0,
            combo: 0,
            maxCombo: 0,
            totalNotesHit: 0,
            totalNotes: 0,
          }
      };

    for (songId in songIds)
    {
      scoreDataEasy.score = Std.int(Math.max(scoreDataEasy.score, inputfunkin.save.SaveData.songScores.get('${songId}-easy') ?? 0));
      // scoreDataEasy.accuracy = Math.max(scoreDataEasy.accuracy, inputfunkin.save.SaveData.songCompletion.get('${songId}-easy') ?? 0.0);
    }
    result.setSongScore(songIds[0], 'easy', scoreDataEasy);

    var scoreDataNormal:funkin.save.SaveScoreData =
      {
        score: 0,
        tallies:
          {
            sick: 0,
            good: 0,
            bad: 0,
            shit: 0,
            missed: 0,
            combo: 0,
            maxCombo: 0,
            totalNotesHit: 0,
            totalNotes: 0,
          }
      };

    for (songId in songIds)
    {
      scoreDataNormal.score = Std.int(Math.max(scoreDataNormal.score, inputfunkin.save.SaveData.songScores.get('${songId}') ?? 0));
      // scoreDataNormal.accuracy = Math.max(scoreDataNormal.accuracy, inputfunkin.save.SaveData.songCompletion.get('${songId}') ?? 0.0);
    }
    result.setSongScore(songIds[0], 'normal', scoreDataNormal);

    var scoreDataHard:funkin.save.SaveScoreData =
      {
        score: 0,
        tallies:
          {
            sick: 0,
            good: 0,
            bad: 0,
            shit: 0,
            missed: 0,
            combo: 0,
            maxCombo: 0,
            totalNotesHit: 0,
            totalNotes: 0,
          }
      };

    for (songId in songIds)
    {
      scoreDataHard.score = Std.int(Math.max(scoreDataHard.score, inputfunkin.save.SaveData.songScores.get('${songId}-hard') ?? 0));
      // scoreDataHard.accuracy = Math.max(scoreDataHard.accuracy, inputfunkin.save.SaveData.songCompletion.get('${songId}-hard') ?? 0.0);
    }
    result.setSongScore(songIds[0], 'hard', scoreDataHard);
  }

  static function migrateLegacyControls(result:funkin.save.Save, inputfunkin.save.SaveData:Rawfunkin.save.SaveData_v1_0_0):Void
  {
    var p1Data = inputfunkin.save.SaveData?.controls?.p1;
    if (p1Data != null)
    {
      migrateLegacyPlayerControls(result, 1, p1Data);
    }

    var p2Data = inputfunkin.save.SaveData?.controls?.p2;
    if (p2Data != null)
    {
      migrateLegacyPlayerControls(result, 2, p2Data);
    }
  }

  static function migrateLegacyPlayerControls(result:funkin.save.Save, playerId:Int, controlsData:funkin.save.SavePlayerControlsData_v1_0_0):Void
  {
    var outputKeyControls:funkin.save.SaveControlsData =
      {
        ACCEPT: controlsData?.keys?.ACCEPT ?? null,
        BACK: controlsData?.keys?.BACK ?? null,
        CUTSCENE_ADVANCE: controlsData?.keys?.CUTSCENE_ADVANCE ?? null,
        NOTE_DOWN: controlsData?.keys?.NOTE_DOWN ?? null,
        NOTE_LEFT: controlsData?.keys?.NOTE_LEFT ?? null,
        NOTE_RIGHT: controlsData?.keys?.NOTE_RIGHT ?? null,
        NOTE_UP: controlsData?.keys?.NOTE_UP ?? null,
        PAUSE: controlsData?.keys?.PAUSE ?? null,
        RESET: controlsData?.keys?.RESET ?? null,
        UI_DOWN: controlsData?.keys?.UI_DOWN ?? null,
        UI_LEFT: controlsData?.keys?.UI_LEFT ?? null,
        UI_RIGHT: controlsData?.keys?.UI_RIGHT ?? null,
        UI_UP: controlsData?.keys?.UI_UP ?? null,
        VOLUME_DOWN: controlsData?.keys?.VOLUME_DOWN ?? null,
        VOLUME_MUTE: controlsData?.keys?.VOLUME_MUTE ?? null,
        VOLUME_UP: controlsData?.keys?.VOLUME_UP ?? null,
      };

    var outputPadControls:funkin.save.SaveControlsData =
      {
        ACCEPT: controlsData?.pad?.ACCEPT ?? null,
        BACK: controlsData?.pad?.BACK ?? null,
        CUTSCENE_ADVANCE: controlsData?.pad?.CUTSCENE_ADVANCE ?? null,
        NOTE_DOWN: controlsData?.pad?.NOTE_DOWN ?? null,
        NOTE_LEFT: controlsData?.pad?.NOTE_LEFT ?? null,
        NOTE_RIGHT: controlsData?.pad?.NOTE_RIGHT ?? null,
        NOTE_UP: controlsData?.pad?.NOTE_UP ?? null,
        PAUSE: controlsData?.pad?.PAUSE ?? null,
        RESET: controlsData?.pad?.RESET ?? null,
        UI_DOWN: controlsData?.pad?.UI_DOWN ?? null,
        UI_LEFT: controlsData?.pad?.UI_LEFT ?? null,
        UI_RIGHT: controlsData?.pad?.UI_RIGHT ?? null,
        UI_UP: controlsData?.pad?.UI_UP ?? null,
        VOLUME_DOWN: controlsData?.pad?.VOLUME_DOWN ?? null,
        VOLUME_MUTE: controlsData?.pad?.VOLUME_MUTE ?? null,
        VOLUME_UP: controlsData?.pad?.VOLUME_UP ?? null,
      };

    result.setControls(playerId, Keys, outputKeyControls);
    result.setControls(playerId, Gamepad(0), outputPadControls);
  }
}