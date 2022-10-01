package grafex.states;

import grafex.system.log.GrfxLogger;
import grafex.system.typedefs.GrfxCredits;
import haxe.Json;
import grafex.sprites.attached.AttachedSprite;
import grafex.sprites.Alphabet;
import grafex.system.Paths;
import grafex.system.statesystem.MusicBeatState;
import grafex.util.Utils;
#if desktop
import external.Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import sys.FileSystem;
import sys.io.File;
import lime.utils.Assets;

using StringTools;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var descBox:AttachedSprite;

	var offsetThing:Float = -75;

	override function create()
	{
		GrfxLogger.log('info', 'Switched state to: ' + Type.getClassName(Type.getClass(this)));
		
		chechForRoll();
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		persistentUpdate = true;
		
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
        #if MODS_ALLOWED
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path))
		{
			var leMods:Array<String> = Utils.coolTextFile(path);
			for (i in 0...leMods.length)
			{
				if(leMods.length > 1 && leMods[0].length > 0) {
					var modSplit:Array<String> = leMods[i].split('|');
					if(!Paths.ignoreModFolders.contains(modSplit[0].toLowerCase()) && !modsAdded.contains(modSplit[0]))
					{
						if(modSplit[1] == '1')
							{
								trace('CHAT, IS IT WORKONG?');
								//convertCredits(modSplit[0]);
								pushModCreditsToList(modSplit[0]);
							}		
						else
							modsAdded.push(modSplit[0]);
					}
				}
			}
		}
		var arrayOfFolders:Array<String> = Paths.getModDirectories();
		arrayOfFolders.push('');
		for (folder in arrayOfFolders)
		{
			trace('CHAT, IS IT WORKONG?');
			convertCredits(folder);
			pushModCreditsToList(folder);
		}
		#end
	
		var pisspoop:Array<Array<String>> = [ //Name - Icon name - Description - Link - BG Color
			['Grafex Engine by'],
		    ['JustXale',			'xale',				'Programmer',													'https://github.com/JustXale',			'f7a300'],
		    ['PurSnake',			'snake',			'Programmer',													'https://github.com/PurSnake', 			'C549DB'],
			['MrOlegTitov', 		'olegus', 			'Programmer', 													'https://github.com/MrOlegTitov', 		'9E29CF'],
			['LenyaTheCat',			'lenya',			'Artist',														'https://youtube.com/channel/UCMQ8ExqI_qKt8a6OrhHGkbQ', 'ffffff'],
			['NotGeorg', 			null,				'Custom Arrows Skin Artist',									'https://twitter.com/VolkovGeorg', 		'919191'],
            [''],
			['Additional Credits'],
			['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',								'https://twitter.com/Shadow_Mario_',	'444444'],
			['RiverOaken',			'river',			'Main Artist/Animator of Psych Engine',							'https://twitter.com/RiverOaken',		'B42F71'],
			['shubs',				'shubs',			'Additional Programmer of Psych Engine',						'https://twitter.com/yoshubs',			'5E99DF'],
			['bb-panzu',			'bb',				'Ex-Programmer of Psych Engine',								'https://twitter.com/bbsub3',			'3E813A'],
			['iFlicky',				'flicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',		'https://twitter.com/flicky_i',			'9E29CF'],
			['SqirraRNG',			'sqirra',			'Crash Handler and Base code for\nChart Editor\'s Waveform',	'https://twitter.com/gedehari',			'E1843A'],
			['PolybiusProxy',		'proxy',			'.MP4 Video Loader Library (hxCodec)',							'https://twitter.com/polybiusproxy',	'DCD294'],
			['KadeDev',				'kade',				'Maintainer of KE',												'https://twitter.com/kade0912',			'64A250'],
			['Keoiki',				'keoiki',			'Note Splash Animations',										'https://twitter.com/Keoiki_',			'D2D2D2'],
			['Nebula the Zorua',	'nebula',			'LUA JIT Fork and some Lua reworks',							'https://twitter.com/Nebula_Zorua',		'7D40B2'],
			['Smokey',				'smokey',			'Sprite Atlas Support',											'https://twitter.com/Smokey_5_',		'483D92'],
			[''],
			["Funkin' Crew"],
			['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",							'https://twitter.com/ninja_muffin99',	'CF2D2D'],
			['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",								'https://twitter.com/PhantomArcade3K',	'FADC45'],
			['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",								'https://twitter.com/evilsk8r',			'5ABD4B'],
			['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",								'https://twitter.com/kawaisprite',		'378FC7']
		];
		
		for(i in pisspoop){
			creditsStuff.push(i);
		}
	
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, creditsStuff[i][0], !isSelectable, false);
			optionText.isMenuItem = true;
			optionText.screenCenter(X);
			optionText.yAdd -= 70;
			if(isSelectable) {
				optionText.x -= 70;
			}
			optionText.forceX = optionText.x;
			//optionText.yMult = 90;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(isSelectable) {
				if(creditsStuff[i][5] != null)
				{
					Paths.currentModDirectory = creditsStuff[i][5];
				}

				if(creditsStuff[i][1] != null && creditsStuff[i][1] != '')
					{
						var icon:AttachedSprite = new AttachedSprite('credits/' + creditsStuff[i][1]);
						icon.xAdd = optionText.width + 10;
						icon.sprTracker = optionText;
						
						// using a FlxGroup is too much fuss!
						iconArray.push(icon);
						add(icon);
					} 

				if(curSelected == -1) curSelected = i;
			}
		}

		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);
		
		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
		descText.scrollFactor.set();
		//descText.borderSize = 2.4;
		descBox.sprTracker = descText;
		add(descText);

		bg.color = getCurrentBGColor();
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
        if(FlxG.keys.justPressed.F11)
        {
        	FlxG.fullscreen = !FlxG.fullscreen;
        }
		
        if(FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if(!quitting)
			{
				if(creditsStuff.length > 1)
				{
					var shiftMult:Int = 1;
					if(FlxG.keys.pressed.SHIFT) shiftMult = 3;
	
					var upP = controls.UI_UP_P;
					var downP = controls.UI_DOWN_P;
	
					if (upP)
					{
						changeSelection(-1 * shiftMult);
						holdTime = 0;
					}
					if (downP)
					{
						changeSelection(1 * shiftMult);
						holdTime = 0;
					}
	
					if(controls.UI_DOWN || controls.UI_UP)
					{
						var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
						holdTime += elapsed;
						var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
						if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						{
							changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
						}
					}
				}
	
				if(controls.ACCEPT) {
					if (creditsStuff[curSelected][3] == '' || creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length < 4) {
						FlxG.sound.play(Paths.sound('cancelMenu'));
					} else {
						Utils.browserLoad(creditsStuff[curSelected][3]);
					}
				}

				if (controls.BACK)
				{
					if(colorTween != null) {
						colorTween.cancel();
					}
					FlxG.sound.play(Paths.sound('cancelMenu'));
					MusicBeatState.switchState(new MainMenuState());
					quitting = true;
				}
			}
			
			for (item in grpOptions.members)
			{
				if(!item.isBold)
				{
					var lerpVal:Float = Utils.boundTo(elapsed * 12, 0, 1);
					if(item.targetY == 0)
					{
						var lastX:Float = item.x;
						item.screenCenter(X);
						item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
						item.forceX = item.x;
					}
					else
					{
						item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
						item.forceX = item.x;
					}
				}
			}
			super.update(elapsed);
		}
	
		var moveTween:FlxTween = null;

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var newColor:Int =  getCurrentBGColor();
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}
		descText.text = creditsStuff[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 60;

		if(moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	#if MODS_ALLOWED
	private var modsAdded:Array<String> = [];
	function pushModCreditsToList(folder:String)
	{
		if(modsAdded.contains(folder)) return;

		var creditsFile:String = null;
		if(folder != null && folder.trim().length > 0) creditsFile = Paths.mods(folder + '/data/credits/credits.json');
		else creditsFile = Paths.mods('data/credits/credits.json');

		if (FileSystem.exists(creditsFile))
		{
			var firstArray:String = File.getContent(creditsFile);
			var parsedStuff:GrfxCredits = cast Json.parse(firstArray);

			trace(parsedStuff.credits);
			trace(parsedStuff.credits.length);

			if(parsedStuff.credits != null)
			{
				trace('WHEN THE TEST IS TEST OF MY TEST WHILE TESTING, IS IT WORKING CHAT??');
				for(i in 0...parsedStuff.credits.length)
				{
					if(parsedStuff.credits[i].icon.length > 0)
					{
						creditsStuff.push([
							parsedStuff.credits[i].name, 
							(parsedStuff.credits[i].icon != null && parsedStuff.credits[i].icon != '') ? parsedStuff.credits[i].icon : '', 
							(parsedStuff.credits[i].role != null && parsedStuff.credits[i].role != '') ? parsedStuff.credits[i].role : '', 
							(parsedStuff.credits[i].socialLink != null && parsedStuff.credits[i].socialLink != '') ? parsedStuff.credits[i].socialLink : '', 
							(parsedStuff.credits[i].bgColor != null && parsedStuff.credits[i].bgColor != '') ? parsedStuff.credits[i].bgColor : '', 
						]);
					}
					else
					{
						creditsStuff.push([parsedStuff.credits[i].name]);
					}
						
				}
			}

			creditsStuff.push(['']);
		}
		modsAdded.push(folder);
	}

	function convertCredits(folder:String)
	{
		var finalArray:Array<GrfxCredit> = [];
		// just copied code of the function above lol
		if(modsAdded.contains(folder)) return;

		var creditsFile:String = null;
		if(folder != null && folder.trim().length > 0) creditsFile = Paths.mods(folder + '/data/credits');
		else creditsFile = Paths.mods('data/credits');

		if (FileSystem.exists('$creditsFile.txt'))
		{
			var firstarray:Array<String> = File.getContent('$creditsFile.txt').split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				var json = {
					"name": arr[0],
					"icon": arr[1],
					"role": arr[2],
					"socialLink": arr[3],
					"bgColor": arr[4],
				};
				finalArray.push(json);
			}
		}
		var data:GrfxCredits = {
			credits: finalArray,
		};

		var finalData = Json.stringify(data, '\t');

		if(!FileSystem.exists('./$creditsFile/'))
            FileSystem.createDirectory('./$creditsFile/');
       
		File.saveContent('$creditsFile/credits.json', finalData);
	}
	#end

	function getCurrentBGColor()
	{
		var bgColor:String = creditsStuff[curSelected][4];
		if(!bgColor.startsWith('0x')) {
			bgColor = '0xFF' + bgColor;
		}
		return Std.parseInt(bgColor);
	}

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}

	function chechForRoll()
	{
		if(FlxG.random.int(0, 4) <= 1)
		{
			Utils.browserLoad('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
		}
	}
}