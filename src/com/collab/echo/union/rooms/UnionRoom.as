/*
Echo project.

Copyright (C) 2010 Collab

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
package com.collab.echo.union.rooms
{
	import com.collab.echo.core.rooms.BaseRoom;
	import com.collab.echo.model.UserVO;
	import com.collab.echo.net.Connection;
	
	import net.user1.reactor.IClient;
	import net.user1.reactor.Room;
	import net.user1.reactor.RoomEvent;
	import net.user1.reactor.RoomModuleType;
	import net.user1.reactor.RoomModules;
	import net.user1.reactor.RoomSettings;
	import net.user1.reactor.UpdateLevels;
	
	/**
	 * Union-specific room.
	 * 
	 * @author Thijs Triemstra
	 * 
	 * @langversion 3.0
 	 * @playerversion Flash 9
	 */	
	public class UnionRoom extends BaseRoom
	{
		// ====================================
		// PROTECTED VARS
		// ====================================
		
		/**
		 * Used to specify the room modules that should be attached to a
		 * server-side Union room at creation time.
		 */		
		protected var modules					: RoomModules;
		
		/**
		 * A data container describing the configuration settings for
		 * this Union room.
		 */		
		protected var settings					: RoomSettings;
		
		/**
		 * Specifies the amount of information a client wishes to
		 * receive from the server about a room it has either joined
		 * or is observing.
		 */		
		protected var updateLevels				: UpdateLevels;
		
		/**
		 * A place for Union clients to engage in group communication.
		 */		
		protected var room						: Room;
		
		/**
		 * Constructor. 
		 * 
		 * @param id
		 * @param autoJoin
		 * @param watch
		 */		
		public function UnionRoom( id:String, autoJoin:Boolean=false, watch:Boolean=true )
		{
			super( id, autoJoin, watch );
			
			this.modules = new RoomModules();
			
			// specify that the rooms should not "die on empty"; otherwise,
			// each room would automatically be removed when its last occupant leaves
			settings = new RoomSettings();
			settings.dieOnEmpty = false;
			settings.maxClients = -1;
			
			updateLevels = new UpdateLevels();
			updateLevels.roomMessages = true;
			updateLevels.sharedObserverAttributesRoom = true;
		}
		
		// ====================================
		// PUBLIC METHODS
		// ====================================
		
		/**
		 * Create a new Union room.
		 * 
		 * @param connection	Connection with Reactor.
		 * @return 
		 */		
		override public function create( connection:Connection ):void
		{
			super.create( connection );
			
			// create the room
			room = connection.createRoom( id, settings, null, modules );
			
			// listen for union events that we'll turn into BaseRoomEvents
			room.addEventListener( RoomEvent.JOIN_RESULT,		 			joinResult );
			room.addEventListener( RoomEvent.OCCUPANT_COUNT,	 			occupantCount );
			room.addEventListener( RoomEvent.ADD_OCCUPANT, 		 			addOccupant );
			room.addEventListener( RoomEvent.REMOVE_OCCUPANT, 	 			removeOccupant );
			room.addEventListener( RoomEvent.UPDATE_CLIENT_ATTRIBUTE, 		clientAttributeUpdate );
			room.addEventListener( RoomEvent.SYNCHRONIZE,		 			synchronize );
			
			trace( "Creating new " + name + " called: " + id );
			
			if ( autoJoin )
			{
				// join
				trace( "Auto-joining: " + id );
				joinedRoom = false;
				join();
			}
		}
		
		/**
		 * Join the union room.
		 */		
		override public function join():void
		{
			// union specific join command
			room.join( null, updateLevels );
		}
		
		/**
		 * Leave the union room.
		 */		
		override public function leave():void
		{
			// union specific leave command
			room.leave();
		}
		
		/**
		 * Get room occupants.
		 * 
         * @return 
         */        
        override public function getOccupants():Array
        {
        	return room.getOccupants();
        }
        
        /**
		 * Get room occupant ids.
		 * 
         * @return 
         */        
        override public function getOccupantIDs():Array
        {
        	return room.getOccupantIDs();
        }
        
        /**
		 * Parse client into user value object.
		 * 
		 * @param client
		 */		
		override public function parseUser( client:* ):UserVO
		{
			return connection.parseUser( client );
		}
        
        /**
         * @param clientIDs
         * @param attrName
         * @param attrScope
         * @return 
         */        
        override public function getAttributeForClients( clientIDs:Array, attrName:String,
        												 attrScope:String=null):Array
        {
        	return connection.getAttributeForClients( clientIDs, attrName, attrScope );
        }
		
		/**
		 * Add union specific room message listener.
		 * 
		 * @param type
		 * @param method
		 */		
		override public function addMessageListener( type:String, method:Function ):void
        {
        	super.addMessageListener( type, method );
        	
        	if ( room )
        	{
        		// union specific message listener command
				room.addMessageListener( type, method );
        	}
        }
        
        /**
         * Remove union specific room message listener.
         * 
		 * @param type
		 * @param method
		 */		
		override public function removeMessageListener( type:String, method:Function ):void
        {
        	if ( room )
        	{
        		// union specific message listener command
				room.removeMessageListener( type, method );
        	}
        	
        	super.removeMessageListener( type, method );
        }
        
        /**
         * Send a message to a union room.
         * 
         * @param type
         * @param message
         * @param includeSelf
         */        
        override public function sendMessage( type:String, message:String,
        									  includeSelf:Boolean=false ):void
        {
        	if ( room )
        	{
        		room.sendMessage( type, includeSelf, null, message );
        	}
        }

		/**
		 * @param name
		 * @return 
		 */		
		override public function getIPByUserName( name:String ):String
		{
			return connection.getIPByUserName( name );
		}
		
		/**
		 * @param attrName
		 * @param attrValue
		 * @return 
		 */		
		override public function getClientByAttribute( attrName:String,
													   attrValue:String ):*
		{
			return connection.getClientByAttribute( attrName, attrValue );
		}
		
		/**
		 * @param id
		 * @return 
		 */		
		override public function getClientById( id:String ):*
		{
			var result:*;
			
			if ( id != null )
			{
				result = connection.getClientById( id );
			}
			
			return result;
		}
		
		/**
		 * Get own client id.
		 * 
		 * @return 
		 */		
		override public function getClientId():String
		{
			return connection.self.getClientID();
		}
		
		/**
		 * Look up the clientID of a selected client by username
		 * 
		 * @param username
		 * @return 			The client id.
		 */
		override public function getClientIdByUsername( userName:String ):String
		{
			var attr:Object;
			var foundIt:String;
			var attrList:Array;
			var clientName:String;
			var clientList:Array = getOccupantIDs();
			
			// check for users with a name
			if ( clientList && clientList.length > 0 )
			{
				attrList = getAttributeForClients( clientList, UserVO.USERNAME );
				
				if ( attrList && attrList.length > 0 )
				{
					for each ( attr in attrList ) 
					{
						// client from the list
						clientName = attr.value;
						
						if ( clientName != null )
						{
							clientName = clientName.toLowerCase();
						}
						
						// compare to specified user
						if ( clientName == userName.toLowerCase() )
						{
							foundIt = attr.clientID;
							break;
						}
					}
				}
			}
			
			// check for anonymous users
			if ( foundIt == null )
			{
				foundIt = getAnonymousClientIdByUsername( userName );
			}
			
			return foundIt;
		}
		
		/**
		 * Get anonymous user by name, eg. 'user123'.
		 * 
		 * @param name
		 * @return 
		 */		
		public function getAnonymousClientIdByUsername( name:String ):String
		{
			// XXX: move to central constant
			var user:String = "user";
			var client:IClient;
			var clientId:String;
			
			if ( name.substr( 0, user.length ) == user )
			{
				client = getClientById( name.substr( user.length ));
			}
			
			if ( client )
			{
				clientId = client.getClientID();
			}
			
			return clientId;
		}
		
		/**
		 * @private 
		 * @return 
		 */		
		override public function toString():String
		{
			return "<UnionRoom id='" + id + "' />";
		}
		
		// ====================================
		// PROTECTED METHODS
		// ====================================
		
		/**
		 * Invoked when the room was joined.
		 * 
		 * @param event
		 */		
		override protected function joinResult( event:*=null ):void
		{
			// set join flag
			joinedRoom = true;
			
			// register listeners
			registerListeners();
        									   
			super.joinResult( event );
		}
		
		/**
		 * A client attribute was changed.
		 * 
		 * @param event
		 */		
		override protected function clientAttributeUpdate( event:*=null ):void
		{
			// XXX: any constants somewhere?
			if ( event.getChangedAttr().name != "_PING" )
			{
				super.clientAttributeUpdate( event );
			}
			else
			{
				event.preventDefault();
			}
		}
		
		/**
		 * Add RoomModule objects.
	     * 
		 * @param moduleObjects
		 */		
		protected function addModules( ...moduleObjects:Array ):void
		{
			var module:Object;
			for each ( module in moduleObjects )
			{
				if ( module.type == RoomModuleType.CLASS ||
					 module.type == RoomModuleType.SCRIPT )
				{
					trace( "Adding '" + module.type + "' RoomModule: '" + module.alias + "'" );
					modules.addModule( module.alias, module.type );
				}
			}
		}
		
		/**
         * Register message listeners.
         */        
        protected function registerListeners():void
        {
        	var method:Function;
        	var type:Object;
        	
        	for ( type in listeners )
			{
				method = listeners[ type ];
				room.addMessageListener( type.toString(), method );
				
				trace("room.addMessageListener - " + id + ": " + type + ", method: " + method );
			}
        }
		
	}
}