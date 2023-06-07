# CraftStore
ESO Addon

ESOUI page: https://www.esoui.com/downloads/info1590.html

Addon users: Please submit issues here for visibility to other contributors

Addon authors/contributors: As I've become too busy to maintain the addon, please make pull requests to add functionality or fix issues.

# Some Helpers

## Finding motif page and furnishing recipe IDs

The addon Item Finder has proven very handy for this.

## Useful scripts to use in chat

### Current player position

```
* GetUnitWorldPosition(*string* _unitTag_)
** _Returns:_ *integer* _zoneId_, *integer* _worldX_, *integer* _worldY_, *integer* _worldZ_

/script d(GetUnitWorldPosition('player'))
```

### Info about fast travel nodes (wayshrines, dungeons etc.)

Total number of fast travel nodes in the game
```
* GetNumFastTravelNodes()
** _Returns:_ *integer* _numFastTravelNodes_

/script d(GetNumFastTravelNodes())
```

The index and name of the wayshrines in the latest 30 nodes
```
* GetFastTravelNodeInfo(*luaindex* _nodeIndex_)
** _Returns:_ *bool* _known_, *string* _name_, *number* _normalizedX_, *number* _normalizedY_, *textureName* _icon_, *textureName:nilable* _glowIcon_, *[PointOfInterestType|#PointOfInterestType]* _poiType_, *bool* _isShownInCurrentMap_, *bool* _linkedCollectibleIsLocked_

/script first = GetNumFastTravelNodes()-31;
last = GetNumFastTravelNodes()-1;
for ix = first,last do
	known, name, nx, ny, icon, glow, poiType = GetFastTravelNodeInfo(ix)
	if poiType == 1 then
	  d(ix..' - '..name)
	end
end
```


