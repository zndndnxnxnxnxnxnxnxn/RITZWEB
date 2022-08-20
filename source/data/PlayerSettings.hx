package data;

import props.Player;
import ui.Controls;
import ui.DeviceManager;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxSignal;

class PlayerSettings
{
    static public var numPlayers(default, null) = 0;
    static public var numAvatars(default, null) = 0;
    static public var player1(default, null):PlayerSettings;
    static public var player2(default, null):PlayerSettings;
    
    static public final onAvatarAdd = new FlxTypedSignal<PlayerSettings->Void>();
    static public final onAvatarRemove = new FlxTypedSignal<PlayerSettings->Void>();
    
    public var id(default, null):Int;
    
    public final controls:Controls;
    public var avatar:Player;
    public var camera(get, never):PlayCamera;
    inline function get_camera() return avatar.playCamera;
    
    function new(id, scheme)
    {
        this.id = id;
        this.controls = new Controls('player$id', scheme);
    }
    
    public function setKeyboardScheme(scheme)
    {
        controls.setKeyboardScheme(scheme);
    }
    
    static public function addAvatar(avatar:Player):PlayerSettings
    {
        var settings:PlayerSettings;
        
        if (player1 == null)
        {
            player1 = new PlayerSettings(0, Solo);
            ++numPlayers;
        }
        
        if (player1.avatar == null)
            settings = player1;
        else
        {
            if (player2 == null)
            {
                if (player1.controls.keyboardScheme.match(Duo(true)))
                    player2 = new PlayerSettings(1, Duo(false));
                else
                    player2 = new PlayerSettings(1, None);
                ++numPlayers;
            }
            
            if (player2.avatar == null)
                settings = player2;
            else
                throw throw 'Invalid number of players: ${numPlayers+1}';
        }
        ++numAvatars;
        settings.avatar = avatar;
        avatar.settings = settings;
        
        splitCameras();
        
        onAvatarAdd.dispatch(settings);
        
        return settings;
    }
    
    static public function removeAvatar(avatar:Player):Void
    {
        var settings:PlayerSettings;
        
        if (player1 != null && player1.avatar == avatar)
            settings = player1;
        else if(player2 != null && player2.avatar == avatar)
        {
            settings = player2;
            if (player1.controls.keyboardScheme.match(Duo(_)))
                player1.setKeyboardScheme(Solo);
        }
        else
            throw "Cannot remove avatar that is not for a player";
        
        settings.avatar = null;
        while (settings.controls.gamepadsAdded.length > 0)
        {
            final id = settings.controls.gamepadsAdded.shift();
            settings.controls.removeGamepad(id);
            DeviceManager.releaseGamepad(FlxG.gamepads.getByID(id));
        }
        
        --numAvatars;
        
        splitCameras();
        
        onAvatarRemove.dispatch(avatar.settings);
    }
    
    static function splitCameras()
    {
        switch(PlayerSettings.numAvatars)
        {
            case 1:
                var cam:PlayCamera = cast player1.camera;
                cam.width = FlxG.width;
                cam.resetDeadZones();
            case 2:
                var cam:PlayCamera;
                cam = cast player1.camera;
                cam.width = Std.int(FlxG.width / 2);
                cam.resetDeadZones();
                cam = cast player2.camera;
                cam.width = Std.int(FlxG.width / 2);
                cam.x = cam.width;
                cam.resetDeadZones();
        }
    }
    
    static public function init():Void
    {
        if (player1 == null)
        {
            player1 = new PlayerSettings(0, Solo);
            ++numPlayers;
        }
        
        var numGamepads = FlxG.gamepads.numActiveGamepads;
        if (numGamepads > 0)
        {
            var gamepad = FlxG.gamepads.getByID(0);
            if (gamepad == null)
                throw 'Unexpected null gamepad. id:0';
            
            player1.controls.addDefaultGamepad(0);
        }
        
        if (numGamepads > 1)
        {
            if (player2 == null)
            {
                player2 = new PlayerSettings(1, None);
                ++numPlayers;
            }
            
            var gamepad = FlxG.gamepads.getByID(1);
            if (gamepad == null)
                throw 'Unexpected null gamepad. id:0';
            
            player2.controls.addDefaultGamepad(1);
        }
        
        DeviceManager.init();
    }
    
    static public function reset()
    {
        player1 = null;
        player2 = null;
        numPlayers = 0;
    }
}