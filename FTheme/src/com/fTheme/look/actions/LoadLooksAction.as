package com.fTheme.look.actions
{
import com.fTheme.FThemeController;
import com.fTheme.FThemeOptions;
import com.fTheme.look.LookLink;
import com.fTheme.look.LookManager;

import flash.display.Sprite;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.setTimeout;

import mx.collections.ArrayCollection;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.core.FlexGlobals;

/**
 * Dispatched when load process is successfuly completed.
 */
[Event(name="complete", type="flash.events.Event")]
/**
 * Dispatched when load has failed with error.
 */
[Event(name="error", type="flash.events.ErrorEvent")]

/**
 * Loads collection of <code>LookLink</code> instances. Is used in <code>LookManager</code>.
 */
public class LoadLooksAction extends EventDispatcher implements ILoadLooksAction
{
	
	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------

	private var urlLoader:URLLoader;
	
	private var url:String;
	
	private var defaultLookLink:LookLink;
	
	private var options:FThemeOptions = FThemeController.instance.options;
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------
	
	//--------------------------------------
	//  lookLinks
	//--------------------------------------

	private var _lookLinks:ArrayCollection;

	public function get lookLinks():ArrayCollection 
	{
		return _lookLinks;
	}

	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------

	public function start(defaultLookLink:LookLink):void
	{
		this.defaultLookLink = defaultLookLink;
		
		_lookLinks = new ArrayCollection();
		var sort:Sort = new Sort();
		sort.fields = [ new SortField("name") ];
		_lookLinks.sort = sort;
		_lookLinks.refresh();
		
		if (options.showDefaultLook)
			_lookLinks.addItem(defaultLookLink);
		
		var n:int;
		var i:int;
		var lookLink:LookLink;
		if (options.lookLinkNames)
		{
			var names:Array = options.lookLinkNames;
			n = names.length;
			for (i = 0; i < n; i++)
			{
				var name:String = names[i];
				lookLink = new LookLink(name);
				if (options.lookLinksURLBase)
				{
					lookLink.txtFileURL = options.lookLinksURLBase + name + ".txt";
					lookLink.zipFileURL = options.lookLinksURLBase + name + ".zip";
				}
				_lookLinks.addItem(lookLink);
			}
			finish();
		}
		else if (options.lookLinksXMLURL)
		{
			loadLookLinksXML(options.lookLinksXMLURL);
		}
		else
		{
			finish();
		}
	}
	
	private function finish(errorText:String = null):void
	{
		// have at least one look event if options.showDefaultLook is false
		if (errorText && _lookLinks.length == 0)
			_lookLinks.addItem(defaultLookLink);
		if (!options.showDefaultLook)
			FThemeController.instance.lookManager.lookLink = _lookLinks[0];
		
		if (errorText)
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, errorText));
		else
			dispatchEvent(new Event(Event.COMPLETE));
	}

	private function loadLookLinksXML(url:String):void
	{
		this.url = url;
		
		urlLoader = new URLLoader();
		urlLoader.addEventListener(Event.COMPLETE, urlLoader_completeHandler);
		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoader_errorHandler);
		urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoader_errorHandler);
		try
		{
			urlLoader.load(new URLRequest(url));
		}
		catch (error:Error)
		{
			finish("failed to load look XML from \"" + url + "\": " + error.message);
		}
	}
	
	//--------------------------------------------------------------------------
	//
	//  Event handlers
	//
	//--------------------------------------------------------------------------
	
	private function urlLoader_completeHandler(event:Event):void
	{
		// <lookLinks>
		//   ...
		//   <lookLink name="Plastic"[ txtFileURL=""][ zipFileURL=""]/>
		//   ...
		// </lookLinks>
		var xml:XML;
		try
		{
			xml = new XML(urlLoader.data);
		}
		catch (error:Error)
		{
			finish("Failed to parse look XML from \"" + url + "\".\n\n" + error.message);
			return;
		}
		if (xml.name() != "lookLinks")
		{
			finish("Invalid look XML from \"" + url + "\".\n\n" + urlLoader.data);
			return;
		}
		for each (var lookLinkNode:XML in xml.lookLink)
		{
			_lookLinks.addItem(LookLink.fromXML(lookLinkNode));
		}
		finish();
	}
	
	private function urlLoader_errorHandler(event:ErrorEvent):void
	{
		finish("Failed to load look XML from \"" + url + "\".\n\n" + event.text);
	}
	
}
}