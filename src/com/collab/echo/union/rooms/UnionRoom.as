/*
Echo project.

Copyright (C) 2010-2011 Collab

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
	import com.collab.cabin.util.StringUtil;
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
	 * 
	 * @example Creating and auto-joining a new UnionRoom:
	 * 
	 * <listing version="3.0">
	 * // setup server connection
	 * var server:UnionConnection = new UnionConnection("localhost", 9110);
	 * server.addEventListener( BaseConnectionEvent.CONNECT_SUCCESS, handleServerConnect );
	 * 
	 * // setup room for auto-join
	 * var room:UnionRoom = new UnionRoom( "chess", true );
	 * room.addEventListener( BaseRoomEvent.JOIN_RESULT, handleRoomJoin );
	 * 
	 * // connect to union
	 * server.connect();
	 * 
	 * function handleServerConnect( event:BaseConnectionEvent ):void
	 * {
	 *     // connect and join room
	 *     room.connect( server )
	 * }
	 * 
	 * function handleRoomJoin( event:BaseRoomEvent ):void
	 * {
	 *     trace("Welcome in the chess room!");
	 * }</listing>
	 * 
	 * @see com.collab.echo.union.net.UnionConnection UnionConnection
	 */	
	public class UnionRoom extends BaseRoom
	{
		// ====================================
		// PROTECTED VARS
		// ====================================
		
		/**
		 * Used to specify the room modules that should be attached to a
		 * server-side Union room at creation time.
		 * 
		 * @see #addModules()
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
		 * The corresponding room on the Union server.
		 */		
		protected var room						: Room;
		
		/**
		 * Room listeners mapping.
		 * 
		 * @example The contents of this variable:
		 * 
		 * <listing version="3.0">
		 * for ( var cnt:int = 0; cnt &lt; roomListeners.length; cnt++ )
		 * {
		 *     trace( roomListeners[cnt][ 0 ],  // event type
		 *	          roomListeners[cnt][ 1 ]); // function
		 * }</listing>
		 */		
		protected var roomListeners			: Array;
		
		/**
		 * Setup a new Union room. 
		 * 
		 * @param id		Name of the room.
		 * @param autoJoin	Indicates if the room should be joined automatically.
		 * @param watch		Indicates if the room should be watched automatically.
		 */		
		public function UnionRoom( id:String, autoJoin:Boolean=false,
								   watch:Boolean=true )
		{
			super( id, autoJoin, watch );
			
			modules = new RoomModules();
			roomListeners = [
				[ RoomEvent.JOIN_RESULT, 			 joinResult ],
				[ RoomEvent.LEAVE_RESULT, 			 leaveResult ],
				[ RoomEvent.OCCUPANT_COUNT, 		 occupantCount ],
				[ RoomEvent.ADD_OCCUPANT, 			 addOccupant ],
				[ RoomEvent.REMOVE_OCCUPANT, 		 removeOccupant ],
				[ RoomEvent.UPDATE_CLIENT_ATTRIBUTE, clientAttributeUpdate ],
				[ RoomEvent.SYNCHRONIZE, 			 synchronize ]
			];
			
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
		 * Setup a connection for this Union room.
		 * 
		 * Also joins the room when <code>autoJoin</code> is true.
		 * 
		 * @param connection	Connection with Union.
		 * @see #disconnect()
		 * @see com.collab.echo.union.net.UnionConnection UnionConnection
		 */		
		override public function connect( connection:Connection ):void
		{
			super.connect( connection );
			
			// create the room on the union server
			room = connection.createRoom( id, settings, null, modules );
			
			// listen for union events that we'll turn into BaseRoomEvents
			var cnt:int = 0;
			for ( cnt; cnt < roomListeners.length; cnt++ )
			{
				room.addEventListener( roomListeners[cnt][ 0 ],
									   roomListeners[cnt][ 1 ]);
			}
			
			trace( StringUtil.replace( "Creating new %s called: %s", name, id ));
			
			if ( autoJoin )
			{
				// join
				trace( "Auto-joining: " + id );
				joinedRoom = false;
				join();
			}
		}
		
		/**
		 * Close the connection with the Union server for this room.
		 * 
		 * @see #connect()
		 */		
		override public function disconnect():void
		{
			super.disconnect();
			
			if ( room )
			{
				// remove union event listeners
				var cnt:int = 0;
				var type:String;
				for ( cnt; cnt < roomListeners.length; cnt++ )
				{
					type = roomListeners[cnt][ 0 ];
					if ( room.hasEventListener( type ))
					{
						room.removeEventListener( type,
							roomListeners[cnt][ 1 ]);
					}
				}
				
				joinedRoom = false;
				room = null;
			}
		}
		
		/**
		 * Join the Union room.
		 * 
		 * @see #leave()
		 */		
		override public function join():void
		{
			// union specific join command
			if ( room )
			{
				room.join( null, updateLevels );
			}
		}
		
		/**
		 * Leave the Union room.
		 * 
		 * @see #join()
		 */		
		override public function leave():void
		{
			// union specific leave command
			if ( room )
			{
				room.leave();
			}
		}
		
        /**
		 * Parse client into user value object.
		 * 
		 * @param client	IClient instance.
		 * @return 			Returns null if not connected, otherwise
		 * 					a UserVO instance.
		 */		
		override public function parseUser( client:* ):UserVO
		{
			var result:UserVO;
			
			if ( connection )
			{
				result = connection.parseUser( client );
			}
			
			return result;
		}
        
		/**
		 * Add Union specific room message listener.
		 * 
		 * @param type
		 * @param method
		 * @see #removeMessageListener()
		 * @see #hasMessageListener()
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
		 * Indicates if message listener was previously registered via
		 * addMessageListener().
		 * 
		 * @param type
		 * @param method
		 * @return Boolean indicating if the message listener was previously
		 *         registered. 
		 * @see #addMessageListener()
		 * @see #removeMessageListener()
		 */		
		override public function hasMessageListener( type:String,
													 method:Function ):Boolean
		{
			var present:Boolean = super.hasMessageListener( type, method );
			
			if ( room )
			{
				present = room.hasMessageListener( type, method );
			}
			
			return present;
		}
        
        /**
         * Remove Union specific room message listener.
         * 
		 * @param type
		 * @param method
		 * @see #addMessageListener()
		 * @see #hasMessageListener()
		 */		
		override public function removeMessageListener( type:String, method:Function ):void
        {
			if ( room && room.hasMessageListener( type, method ))
			{
    			// union specific message listener command
				room.removeMessageListener( type, method );
				
				super.removeMessageListener( type, method );
			}
        }
        
        /**
         * Send a message to a Union room.
         * 
         * @param type
         * @param message
         * @param includeSelf
		 * @see #addMessageListener()
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
		 * Get own client id.
		 * 
		 * Returns null if the room is not connected.
		 * 
		 * @example Retrieving own client id:
		 * 
		 * <listing version="3.0">
		 * var myID:String = room.getClientId();
		 * trace( myID ); // 12</listing>
		 * 
		 * @return String indicating the user's client id on the Union server.
		 * @see #getClientIdByUsername()
		 * @see #getAnonymousClientIdByUsername()
		 */		
		override public function getClientId():String
		{
			var result:String;
			
			if ( connection )
			{
				result = connection.self.getClientID();
			}
			
			return result;
		}

		/**
		 * Get room occupants.
		 * 
		 * @return List of IClient instances or null when room was not joined.
		 * @see #getOccupantIDs()
		 */        
		override public function getOccupants():Array
		{
			var result:Array;
			
			if ( room )
			{
				result = room.getOccupants();
			}
			
			return result;
		}
		
		/**
		 * Get room occupant ids.
		 * 
		 * Returns an empty array when the room was not joined.
		 * 
		 * @example Retrieving the room's occupant id's:
		 * 
		 * <listing version="3.0">
		 * var ids:Array = room.getOccupantIDs();
		 * trace( ids ); // 12,14</listing>
		 * 
		 * @return List of string ids.
		 * @see #getOccupants()
		 */        
		override public function getOccupantIDs():Array
		{
			var result:Array;
			
			if ( room )
			{
				result = room.getOccupantIDs();
			}
			
			return result;
		}
		
		/**
		 * Get IP address for username.
		 * 
		 * @example Retrieving the IP for a user called 'thijs':
		 * 
		 * <listing version="3.0">
		 * var ip:String = room.getIPByUserName( "thijs" );
		 * trace( ip ); // 0:0:0:0:0:0:0:1</listing>
		 * 
		 * @param name The username associated with the IP address.
		 * @return The IP address in IPv6 or IPv4 format.
		 */		
		override public function getIPByUserName( name:String ):String
		{
			var result:String;
			
			if ( connection )
			{
				result = connection.getIPByUserName( name );
			}
			
			return result;
		}
		
		/**
		 * Get client by attribute name and value.
		 * 
		 * @param attrName
		 * @param attrValue
		 * @return 
		 * @see #getClientById()
		 */		
		override public function getClientByAttribute( attrName:String,
													   attrValue:String ):*
		{
			var result:*;
			
			if ( connection )
			{
				result = connection.getClientByAttribute( attrName, attrValue ); 
			}
			
			return result;
		}
		
		/**
		 * Get client by id.
		 * 
		 * @param id
		 * @return 
		 * @see #getClientByAttribute()
		 */		
		override public function getClientById( id:String ):*
		{
			var result:*;
			
			if ( id && connection )
			{
				result = connection.getClientById( id );
			}
			
			return result;
		}
		
		/**
		 * Get list of attributes for occupants by attrName.
		 * 
		 * @param clientIDs
		 * @param attrName
		 * @param attrScope
		 * @return
		 */        
		override public function getAttributeForClients( clientIDs:Array, attrName:String,
														 attrScope:String=null):Array
		{
			var result:Array;
			
			if ( connection )
			{
				result = connection.getAttributeForClients( clientIDs,
					attrName, attrScope );	
			}
			
			return result;
		}
		
		/**
		 * Look up the clientID of a selected client by username
		 * 
		 * @example Retrieving the client id for a user called 'ben':
		 * 
		 * <listing version="3.0">
		 * var id:String = room.getClientIdByUsername( "ben" );
		 * trace( id ); // 15</listing>
		 * 
		 * @param username
		 * @return 			The client id.
		 * @see #getClientId()
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
			
			if ( name && name.substr( 0, user.length ) == user &&
				 name.length > user.length )
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
			return StringUtil.replace( "<UnionRoom id='%s' />", id );
		}
		
		// ====================================
		// PROTECTED METHODS
		// ====================================
		
		/**
		 * Invoked when the user joined the room.
		 * 
		 * @param event
		 * @private
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
		 * Invoked when the current client left the room.
		 * 
		 * @param event
		 * @private
		 */		
		override protected function leaveResult( event:*=null ):void
		{
			// set join flag
			joinedRoom = false;
			
			// XXX: unregister listeners?
			
			super.leaveResult( event );
		}
		
		/**
		 * A client attribute was changed.
		 * 
		 * @param event
		 * @private
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
		 * @see #modules
		 */		
		protected function addModules( ...moduleObjects:Array ):void
		{
			var module:Object;

			for each ( module in moduleObjects )
			{
				if ( module.type == RoomModuleType.CLASS ||
					 module.type == RoomModuleType.SCRIPT )
				{
					trace( StringUtil.replace( "Adding '%s' RoomModule: '%s'",
						   module.type, module.alias ));

					modules.addModule( module.alias, module.type );
				}
			}
		}
		
		/**
         * Register message listeners.
		 * 
		 * @private
         */        
        protected function registerListeners():void
        {
        	var method:Function;
        	var type:Object;
        	
        	for ( type in listeners )
			{
				method = listeners[ type ];
				room.addMessageListener( type.toString(), method );
				
				trace( StringUtil.replace( "room.addMessageListener - %s: %s, method: %s",
					   id, type, method ));
			}
        }
		
	}
}