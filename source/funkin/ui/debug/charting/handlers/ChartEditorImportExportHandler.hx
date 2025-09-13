package funkin.ui.debug.charting.handlers;

import funkin.data.song.SongNoteDataUtils;
import funkin.util.VersionUtil;
import funkin.util.DateUtil;
import haxe.io.Path;
import funkin.util.SortUtil;
import funkin.util.FileUtil;
import funkin.util.FileUtil.FileWriteMode;
import haxe.io.Bytes;
import funkin.play.song.Song;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongRegistry;
import funkin.data.song.importer.ChartManifestData;
import thx.semver.Version as SemverVersion;

/**
 * Contains functions for importing, loading, saving, and exporting charts.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorImportExportHandler
{
  public static final BACKUPS_PATH:String = './backups/';

  // ==================================================
  // SONG LOADING
  // ==================================================

  public static function loadSongAsTemplate(state:ChartEditorState, songId:String, targetSongDifficulty:String = null, targetSongVariation:String = null):Void
  {
    trace('===============START');

    var song:Null<Song> = SongRegistry.instance.fetchEntry(songId, {variation: targetSongVariation});
    if (song == null) return;

    var rawSongMetadata:Array<SongMetadata> = song.getRawMetadata();
    var songMetadata:Map<String, SongMetadata> = [];
    var songChartData:Map<String, SongChartData> = [];

    for (metadata in rawSongMetadata)
    {
      if (metadata == null) continue;
      var variation = (metadata.variation == null || metadata.variation == '') ? Constants.DEFAULT_VARIATION : metadata.variation;

      var metadataClone:SongMetadata = metadata.clone();
      metadataClone.variation = variation;
      if (metadataClone != null) songMetadata.set(variation, metadataClone);

      var chartData:Null<SongChartData> = SongRegistry.instance.parseEntryChartData(songId, metadata.variation);
      if (chartData != null) songChartData.set(variation, chartData);
    }

    loadSong(state, songMetadata, songChartData, new ChartManifestData(songId));
    state.sortChartData();

    ChartEditorAudioHandler.wipeInstrumentalData(state);
    ChartEditorAudioHandler.wipeVocalData(state);

    for (variation in state.availableVariations)
    {
      if (variation == Constants.DEFAULT_VARIATION)
        state.loadInstFromAsset(Paths.inst(songId));
      else
        state.loadInstFromAsset(Paths.inst(songId, '-$variation'), variation);

      for (difficultyId in song.listDifficulties(variation, true, true))
      {
        var diff:Null<SongDifficulty> = song.getDifficulty(difficultyId, variation);
        if (diff == null) continue;

        var instId:String = diff.variation == Constants.DEFAULT_VARIATION ? '' : diff.variation;
        var voiceList:Array<String> = diff.buildVoiceList();

        if (voiceList.length == 2)
        {
          state.loadVocalsFromAsset(voiceList[0], diff.characters.player, instId);
          state.loadVocalsFromAsset(voiceList[1], diff.characters.opponent, instId);
        }
        else if (voiceList.length == 1)
        {
          state.loadVocalsFromAsset(voiceList[0], diff.characters.player, instId);
        }
        else
        {
          trace('[WARN] Strange quantity of voice paths for difficulty ${difficultyId}: ${voiceList.length}');
        }

        if (targetSongDifficulty != null && targetSongDifficulty != state.selectedDifficulty && targetSongDifficulty == diff.difficulty)
          state.selectedDifficulty = targetSongDifficulty;

        if (targetSongVariation != null && targetSongVariation != state.selectedVariation && targetSongVariation == diff.variation)
          state.selectedVariation = targetSongVariation;
      }
    }

    state.isHaxeUIDialogOpen = false;
    state.currentWorkingFilePath = null;
    state.switchToCurrentInstrumental();
    state.postLoadInstrumental();
    state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    for (metadata in rawSongMetadata)
    {
      if (metadata.variation == state.selectedVariation)
        state.success('Success', 'Loaded song (${metadata.songName})');
    }

    trace('===============END');
  }

  public static function loadSong(state:ChartEditorState, newSongMetadata:Map<String, SongMetadata>, newSongChartData:Map<String, SongChartData>,
      ?newSongManifestData:ChartManifestData):Void
  {
    state.songMetadata = newSongMetadata;
    state.songChartData = newSongChartData;
    if (newSongManifestData != null) state.songManifestData = newSongManifestData;

    if (!state.songMetadata.exists(state.selectedVariation))
      state.selectedVariation = Constants.DEFAULT_VARIATION;

    if (state.availableDifficulties.indexOf(state.selectedDifficulty) < 0)
      state.selectedDifficulty = state.availableDifficulties[0];

    var delay:Float = 0.5;
    for (variation => chart in state.songChartData)
    {
      var metadata:SongMetadata = state.songMetadata[variation] ?? continue;
      var stackedNotesCount:Int = 0;
      var affectedDiffs:Array<String> = [];

      for (diff => notes in chart.notes)
      {
        if (!metadata.playData.difficulties.contains(diff)) continue;
        var count:Int = SongNoteDataUtils.listStackedNotes(notes, 0, false).length;
        if (count > 0)
        {
          affectedDiffs.push(diff.toTitleCase());
          stackedNotesCount += count;
        }
      }

      if (stackedNotesCount > 0)
      {
        affectedDiffs.sort(SortUtil.defaultsThenAlphabetically.bind(['Easy', 'Normal', 'Hard', 'Erect', 'Nightmare']));
        flixel.util.FlxTimer.wait(delay, () -> {
          state.warning('Stacked Notes Detected',
            'Found $stackedNotesCount stacked note(s) in \'${variation.toTitleCase()}\' variation, ' +
            'on ${affectedDiffs.joinPlural()} difficult${affectedDiffs.length > 1 ? 'ies' : 'y'}.');
        });
        delay *= 1.5;
      }
    }

    Conductor.instance.forceBPM(null);
    Conductor.instance.instrumentalOffset = state.currentInstrumentalOffset;
    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);
    state.updateTimeSignature();

    state.notePreviewDirty = true;
    state.notePreviewViewportBoundsDirty = true;
    state.difficultySelectDirty = true;
    state.opponentPreviewDirty = true;
    state.playerPreviewDirty = true;

    if (state.audioInstTrack != null)
    {
      state.audioInstTrack.stop();
      state.audioInstTrack = null;
    }
    state.audioVocalTrackGroup.stop();
    state.audioVocalTrackGroup.clear();

    state.undoHistory = [];
    state.redoHistory = [];
    state.commandHistoryDirty = true;
  }

  // ==================================================
  // BACKUP HELPERS
  // ==================================================

  public static function getLatestBackupPath():Null<String>
  {
    #if sys
    FileUtil.createDirIfNotExists(BACKUPS_PATH);
    var entries:Array<String> = sys.FileSystem.readDirectory(BACKUPS_PATH);
    entries.sort(SortUtil.alphabetically);
    var latestBackupPath:Null<String> = entries[(entries.length - 1)];
    if (latestBackupPath == null) return null;
    return haxe.io.Path.join([BACKUPS_PATH, latestBackupPath]);
    #else
    return null;
    #end
  }

  public static function getLatestBackupDate():Null<Date>
  {
    #if sys
    var latestBackupPath:Null<String> = getLatestBackupPath();
    if (latestBackupPath == null) return null;

    var latestBackupName:String = haxe.io.Path.withoutDirectory(latestBackupPath);
    latestBackupName = haxe.io.Path.withoutExtension(latestBackupName);

    var parts = latestBackupName.split('-');
    var year:Int = Std.parseInt(parts[2] ?? '0') ?? 0;
    var month:Int = Std.parseInt(parts[3] ?? '1') ?? 1;
    var day:Int = Std.parseInt(parts[4] ?? '0') ?? 0;
    var hour:Int = Std.parseInt(parts[5] ?? '0') ?? 0;
    var minute:Int = Std.parseInt(parts[6] ?? '0') ?? 0;
    var second:Int = Std.parseInt(parts[7] ?? '0') ?? 0;

    return new Date(year, month - 1, day, hour, minute, second);
    #else
    return null;
    #end
  }

  // ==================================================
  // EXPORT
  // ==================================================

  public static function exportAllSongData(state:ChartEditorState, force:Bool = false, targetPath:Null<String>, ?onSaveCb:String->Void,
      ?onCancelCb:Void->Void):Void
  {
    var zipEntries:Array<haxe.zip.Entry> = [];
    var variations = state.availableVariations;

    if (state.currentSongMetadata.playData.difficulties.pushUnique(state.selectedDifficulty))
      state.difficultySelectDirty = true;

    for (variation in variations)
    {
      var variationId:String = (variation == '' || variation == 'default' || variation == 'normal') ? '' : variation;
      var variationMetadata:Null<SongMetadata> = state.songMetadata.get(variation);
      var variationChart:Null<SongChartData> = state.songChartData.get(variation);

      if (variationId == '')
      {
        if (variationMetadata != null)
        {
          variationMetadata.version = funkin.data.song.SongRegistry.SONG_METADATA_VERSION;
          variationMetadata.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;
          zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-metadata.json', variationMetadata.serialize()));
        }
        if (variationChart != null)
        {
          variationChart.version = funkin.data.song.SongRegistry.SONG_CHART_DATA_VERSION;
          variationChart.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;
          zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-chart.json', variationChart.serialize()));
        }
      }
      else
      {
        if (variationMetadata != null)
          zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-metadata-$variationId.json', variationMetadata.serialize()));
        if (variationChart != null)
        {
          variationChart.version = funkin.data.song.SongRegistry.SONG_CHART_DATA_VERSION;
          variationChart.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;
          zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-chart-$variationId.json', variationChart.serialize()));
        }
      }
    }

    if (state.audioInstTrackData != null) zipEntries = zipEntries.concat(state.makeZIPEntriesFromInstrumentals());
    if (state.audioVocalTrackData != null) zipEntries = zipEntries.concat(state.makeZIPEntriesFromVocals());

    zipEntries.push(FileUtil.makeZIPEntry('manifest.json', state.songManifestData.serialize()));
    trace('Exporting ${zipEntries.length} files to ZIP...');

    if (force)
    {
      var targetMode:FileWriteMode = Force;
      if (targetPath == null)
      {
        targetMode = Skip;
        targetPath = Path.join([BACKUPS_PATH, 'chart-editor-${DateUtil.generateTimestamp()}.${Constants.EXT_CHART}']);
        trace('Force exporting to $targetPath...');
        try
        {
          FileUtil.saveFilesAsZIPToPath(zipEntries, targetPath, targetMode);
          if (onSaveCb != null) onSaveCb(targetPath);
        }
        catch (e:Dynamic)
        {
          if (onCancelCb != null) onCancelCb();
        }
      }
      else
      {
        trace('Force exporting to $targetPath...');
        try
        {
          FileUtil.saveChartAsFNFC(zipEntries, onSave, onCancel, '${state.currentSongId}.${Constants.EXT_CHART}');
          state.saveDataDirty = false;
          if (onSaveCb != null) onSaveCb(targetPath);
        }
        catch (e:Dynamic)
        {
          if (onCancelCb != null) onCancelCb();
        }
      }
    }
    else
    {
      var onSave:Array<String>->Void = function(paths:Array<String>) {
        if (paths.length != 1)
        {
          trace('[WARN] Could not get save path.');
          state.applyWindowTitle();
        }
        else
        {
          trace('Saved to "${paths[0]}"');
          state.currentWorkingFilePath = paths[0];
          state.applyWindowTitle();
          if (onSaveCb != null) onSaveCb(paths[0]);
        }
      };

      var onCancel:Void->Void = function() {
        trace('Export cancelled.');
        if (onCancelCb != null) onCancelCb();
      };

      trace('Exporting to user-defined location...');
      try
      {
        FileUtil.saveChartAsFNFC(zipEntries, onSave, onCancel, '${state.currentSongId}.${Constants.EXT_CHART}');
        state.saveDataDirty = false;
      }
      catch (e:Dynamic)
      {
        trace('Import/Export failed: $e');
      }
    }
  }
}
