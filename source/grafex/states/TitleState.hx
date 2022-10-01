package grafex.states;


import grafex.data.EngineData;

import grafex.system.statesystem.MusicBeatState;
import grafex.system.Paths;
import grafex.system.Conductor;
import grafex.system.log.GrfxLogger;

import grafex.sprites.Alphabet;

import grafex.effects.shaders.ColorSwap;
import grafex.effects.ColorblindFilters;

import grafex.states.MainMenuState;
import grafex.states.substates.PrelaunchingState;

import grafex.util.PlayerSettings;
import grafex.util.ClientPrefs;
import grafex.util.Highscore;
import grafex.util.Utils;

#if desktop
import external.Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.addons.effects.FlxTrail;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import grafex.data.WeekData;
import openfl.display.BitmapData;
import sys.FileSystem;
import sys.io.File;
import flixel.addons.display.FlxBackdrop;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import lime.ui.WindowAttributes;

using StringTools;

typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int,
	logoBlTray:Bool,
	backdropImage:String,
	backdropImageVelocityX:Int,
	backdropImageVelocityY:Int
}

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;
    public static var fromMainMenu:Bool = false;
    public static var skipped:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	var mustUpdate:Bool = false;
	
	public static var titleJSON:TitleData;
	
	public static var updateVersion:String = '';

	override public function create():Void
	{
		PlayerSettings.init();
		
		GrfxLogger.log('info', 'Switched state to: ' + Type.getClassName(Type.getClass(this)));
		
        Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end

		Application.current.window.title = Main.appTitle;
        WeekData.loadTheFirstEnabledMod();

    	FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		
		#if (desktop && MODS_ALLOWED)
		var path = "mods/" + Paths.currentModDirectory + "/images/gfDanceTitle.json";
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)) {
			path = "mods/images/gfDanceTitle.json";
		}
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)) {
			path = "assets/images/gfDanceTitle.json";
		}
		//trace(path, FileSystem.exists(path));
		titleJSON = Json.parse(File.getContent(path));
		#else
		var path = Paths.getPreloadPath("images/gfDanceTitle.json");
		titleJSON = Json.parse(Assets.getText(path)); 
		#end

		if(titleJSON == null)
		{	
	    	titleJSON = {	
	            titlex: -150,
	            titley: -100,
	            startx: 100,
	            starty: 576,
	            gfx: 512,
	            gfy :40,
	            backgroundSprite: "",
	            bpm: 102,
                logoBlTray: true,
                backdropImage: "titleBg",
                backdropImageVelocityX: 70,
                backdropImageVelocityY: 70
            };
		}

		curWacky = FlxG.random.getObject(getIntroTextShit());

		// DEBUG BULLSHIT

		swagShader = new ColorSwap();
		super.create();

        bgFlash = new FlxSprite(0, 0).loadGraphic(Paths.image('bgFlash'));
		bgFlash.visible = true;
		bgFlash.alpha = 0;
		bgFlash.scale.set(2, 2);
		bgFlash.updateHitbox();
		bgFlash.antialiasing = true;
		add(bgFlash);


		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		#if desktop
		DiscordClient.initialize();
		Application.current.onExit.add (function (exitCode) {
			DiscordClient.shutdown();
		});
		#end
		if (initialized)
			startIntro();
		else
		{
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
	#end                
	}

	var logoBl:FlxSprite;
    var logoBltrail:FlxTrail;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;
    var bgMenu:FlxBackdrop;
    var bgFlash:FlxSprite;
	var exitText:FlxText;

	function startIntro()
	{
		ColorblindFilters.applyFiltersOnGame();
		if (!initialized)
		{
			if(FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
		}

        if(!fromMainMenu)
			Conductor.changeBPM(titleJSON.bpm);

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none"){
			bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
		}else{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}
        // bg.antialiasing = ClientPrefs.globalAntialiasing;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();
		add(bg);

		if(titleJSON.backdropImage == null)
			titleJSON.backdropImage = 'titleBg';
        bgMenu = new FlxBackdrop(Paths.image(titleJSON.backdropImage), 10, 0, true, true);
		bgMenu.color = 0x7208A0;
		bgMenu.alpha = 0.6;
        bgMenu.velocity.set(titleJSON.backdropImageVelocityX, titleJSON.backdropImageVelocityY); //thats it :D- snake
		add(bgMenu);

		logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
			
		logoBl.antialiasing = ClientPrefs.globalAntialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 1, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();

		swagShader = new ColorSwap();

		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);
	
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
	
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		add(gfDance);
		gfDance.shader = swagShader.shader;
		if(titleJSON.logoBlTray)
		{
        logoBltrail = new FlxTrail(logoBl, 24, 0, 0.4, 0.02);
		add(logoBltrail);
		}
 
		add(logoBl);
        logoBltrail.shader = swagShader.shader;
		logoBl.shader = swagShader.shader;
       
        FlxTween.tween(logoBl, {y: logoBl.y + 80}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG}); //Bruh -snake

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);		
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}

		if (animFrames.length > 0) {
			newTitle = true;

			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else {
			newTitle = false;

			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.antialiasing = ClientPrefs.globalAntialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = true;

		exitText = new FlxText(-300, 0, FlxG.width, 'Exiting game...', 32);
		exitText.alpha = 0;
        exitText.borderColor = FlxColor.BLACK;
        exitText.borderSize = 3;
        exitText.borderStyle = FlxTextBorderStyle.OUTLINE;
        exitText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
        add(exitText);

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	var newTitle:Bool = false;
	var titleTimer:Float = 0;
	var timer:Float = 0;

	override function update(elapsed:Float)
	{
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
        FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, 0.95);

		if(FlxG.keys.justPressed.F11)
            FlxG.fullscreen = !FlxG.fullscreen;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
        var tryExitGame:Bool = FlxG.keys.justPressed.ESCAPE || controls.BACK;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
		}

		if (newTitle) {
			titleTimer += Utils.boundTo(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		// EASTER EGG

		if (!transitioning && skippedIntro)
		{
        	if(skipped == false) {
				if(ClientPrefs.skipTitleState) {
					if (titleText != null)
						titleText.animation.play('press');
					//FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
                    var skipBlack:FlxSprite;  
                    skipBlack = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
                    add(skipBlack);
					transitioning = true;
					
                	FlxTween.tween(FlxG.camera, {zoom: 1.04}, 0.2, {ease: FlxEase.cubeInOut, type: ONESHOT, startDelay: 0});
                	FlxTween.tween(FlxG.camera, {zoom: 1}, 0.2, {ease: FlxEase.cubeInOut, type: ONESHOT, startDelay: 0.25});
					FlxTween.tween(gfDance, {y:2000}, 2.5, {ease: FlxEase.expoInOut});
					FlxTween.tween(titleText, {y: 2000}, 2.5, {ease: FlxEase.expoInOut});
	        		FlxTween.tween(logoBl, {alpha: 0}, 1.2, {ease: FlxEase.expoInOut});
					FlxTween.tween(logoBl, {y: 2000}, 2.5, {ease: FlxEase.expoInOut});
					FlxTween.tween(bgFlash, {y: 2000}, 2, {ease: FlxEase.expoInOut});
                	FlxTween.tween(bgMenu, {x: -1000}, 5, {ease: FlxEase.expoInOut});

					var skippedText:FlxText = new FlxText(450, 300, "SKIPPED...", 80);
					skippedText.setFormat("VCR OSD Mono", 80, FlxColor.WHITE, CENTER);
					add(skippedText);

					new FlxTimer().start(3, function(tmr:FlxTimer) {
						skippedText.destroy();
					});

					skipped = true; // true

					new FlxTimer().start(1, function(tmr:FlxTimer)
					{

						MusicBeatState.switchState(new MainMenuState());
						closedState = true;
					});
					
				}
			}

			if (newTitle && !pressedEnter)
				{
					var timer:Float = titleTimer;
					if (timer >= 1)
						timer = (-timer) + 2;
	
					timer = FlxEase.quadInOut(timer);
	
					titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
					titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
				}
				
			if(pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(ClientPrefs.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
                FlxTween.tween(FlxG.camera, {zoom: 1.04}, 0.2, {ease: FlxEase.cubeInOut, type: ONESHOT, startDelay: 0});
                FlxTween.tween(FlxG.camera, {zoom: 1}, 0.2, {ease: FlxEase.cubeInOut, type: ONESHOT, startDelay: 0.25});
				FlxTween.tween(gfDance, {y:2000}, 2.5, {ease: FlxEase.expoInOut});
				FlxTween.tween(titleText, {y: 2000}, 2.5, {ease: FlxEase.expoInOut});
	        	FlxTween.tween(logoBl, {alpha: 0}, 1.2, {ease: FlxEase.expoInOut});
				FlxTween.tween(logoBl, {y: 2000}, 2.5, {ease: FlxEase.expoInOut});
				FlxTween.tween(bgFlash, {y: 2000}, 2, {ease: FlxEase.expoInOut});
                FlxTween.tween(bgMenu, {x: -1000}, 5, {ease: FlxEase.expoInOut});
                           			
				transitioning = true;
                skipped = true; // true

				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					
					closedState = true;
				});
            }

            if (FlxG.keys.pressed.ESCAPE)
			{
				timer += elapsed * 5;
				exitText.alpha = FlxMath.lerp(0, 1, timer / 3);

				if(timer >= 8)
					Sys.exit(0);
			}
			else
			{
				timer = 0;
				exitText.alpha = 0;
			}
		}

		if (pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
			money.y -= 350;
			FlxTween.tween(money, {y: money.y + 350}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.0});
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
			coolText.y += 750;
		    FlxTween.tween(coolText, {y: coolText.y - 750}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.0});
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	/*function getCurrentBGColor()
	{
		var bgColor:String = titleJSON.backdropImageColor;
		if(!bgColor.startsWith('0x')) {
			bgColor = '0xFF' + bgColor;
		}
		return Std.parseInt(bgColor);
	}*/

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();
        if(curBeat % 2 == 0)
        	FlxG.camera.zoom += 0.025;

        bgFlash.alpha = 0.25;
        FlxG.log.advanced(curBeat);

		if(logoBl != null) 
			logoBl.animation.play('bump', true);

		if(gfDance != null) {
			danceLeft = !danceLeft;

			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
                    FlxG.sound.music.stop();
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					createCoolText(['Grafex Engine by'], 45);
				case 4:
					for(i in 0...EngineData.devsNicks.length)
					{
						addMoreText(EngineData.devsNicks[i], 45);
					} // HAHA, PROTOGEN OPTIMIZED
											
				case 6:
                    deleteCoolText();
					createCoolText(['Forked', 'from'], 15);
				case 8:
					addMoreText('Psych Engine', 45);			
				case 9:
					deleteCoolText();
				case 10:
					createCoolText([curWacky[0]]);
				case 12:
					addMoreText(curWacky[1]);
				case 13:
					deleteCoolText();
				case 14:
					addMoreText('Friday');
				case 15:
					addMoreText('Night');
				case 16:
					addMoreText('Funkin');
				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(ngSpr);
			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
			skippedIntro = true;
            bgFlash.alpha = 0.25;
            if(!fromMainMenu)
            	FlxG.sound.music.time = 9400;
		}
	}
}
