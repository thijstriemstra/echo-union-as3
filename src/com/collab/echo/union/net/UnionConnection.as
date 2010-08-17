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
package com.collab.echo.union.net
{
	import com.collab.cabin.util.StringUtil;
	import com.collab.echo.core.messages.chat.ChatMessage;
	import com.collab.echo.core.rooms.BaseRoom;
	import com.collab.echo.events.BaseRoomEvent;
	import com.collab.echo.model.UserVO;
	import com.collab.echo.net.Connection;
	import com.collab.echo.union.util.RoomUtils;
	
	import net.user1.logger.Logger;
	import net.user1.reactor.ClientManager;
	import net.user1.reactor.ConnectionManager;
	import net.user1.reactor.IClient;
	import net.user1.reactor.MessageManager;
	import net.user1.reactor.Reactor;
	import net.user1.reactor.ReactorEvent;
	import net.user1.reactor.RoomManager;
	import net.user1.reactor.RoomManagerEvent;
	import net.user1.reactor.XMLSocketConnection;
	
	// ====================================
	// EVENTS
	// ====================================
	
	/**
	 * @eventType com.collab.echo.events.BaseRoomEvent.ROOM_REMOVED
	 */
	[Event(name="roomRemoved", type="com.collab.echo.events.BaseRoomEvent")]
	
	/**
	 * @eventType com.collab.echo.events.BaseRoomEvent.ROOM_ADDED
	 */
	[Event(name="roomAdded", type="com.collab.echo.events.BaseRoomEvent")]
	
	/**
	 * @eventType com.collab.echo.events.BaseRoomEvent.ROOM_COUNT
	 */
	[Event(name="roomCount", type="com.collab.echo.events.BaseRoomEvent")]
	
	/**
	 * Union server connection.
	 * 
	 * @author Thijs Triemstra
	 * 
	 * @langversion 3.0
 	 * @playerversion Flash 9
	 */	
	public class UnionConnection extends Connection
	{
		// ====================================
		// PROTECTED VARS
		// ====================================
		
        protected var reactor			: Reactor;

        // ====================================
		// ACCESSOR/MUTATOR
		// ====================================
		
		/**
		 * Return reference to reactor.self().
		 * 
		 * @return 
		 */		
		override public function get self():*
		{
			return reactor.self();
		}
		
		/**
		 * Reference to reactor.getRoomManager().
		 * 
		 * @return 
		 */		
		private function get roomManager():RoomManager
		{
			return reactor.getRoomManager();
		}
		
		/**
		 * Reference to reactor.getConnectionManager().
		 * 
		 * @return 
		 */		
		private function get connectionManager():ConnectionManager
		{
			return reactor.getConnectionManager();
		}
		
		/**
		 * Reference to reactor.getMessageManager().
		 * 
		 * @return 
		 */		
		private function get messageManager():MessageManager
		{
			return reactor.getMessageManager();
		}
		
		/**
		 * Reference to reactor.getClientManager().
		 * 
		 * @return 
		 */		
		private function get clientManager():ClientManager
		{
			return reactor.getClientManager();
		}
		
		/**
		 * Reference to reactor.getLog().
		 * 
		 * @return 
		 */		
		private function get log():Logger
		{
			return reactor.getLog();
		}
		
		/**
		 * Create new Union connection.
		 * 
		 * @param host
		 * @param port
		 * @param logging
		 * @param logLevel
		 */		
		public function UnionConnection( host:String, port:int,
										 logging:Boolean=true, logLevel:String="info" )
		{
			super( host, port, logging, logLevel );
		}
		
		// ====================================
		// PUBLIC METHODS
		// ====================================
		
		/**
         * Connect to server.
         */		
        override public function connect():void
        {
            if ( url && port )
            {
            	// notify others
				super.connect();

                trace( "Connecting to Union server on " + url + ":" + port );

                // create reactor
                reactor = new Reactor( "", logging );
                
                // logging
                if ( logLevel )
                {
                	log.setLevel( logLevel );
                }
                
                // reactor listeners
                reactor.addEventListener( ReactorEvent.READY, unionConnectionReady );
                reactor.addEventListener( ReactorEvent.CLOSE, unionConnectionClose );
                
                // XXX: replace XML socket connection
                connectionManager.addConnection( new XMLSocketConnection( url, port ));
                
                // connect
                _connected = false;
                reactor.connect();
            }
        }
        
        /**
		 * Parse user.
		 * 
		 * @param client
		 */		
		override public function parseUser( client:* ):UserVO
		{
			var vo:UserVO = new UserVO( client.getClientID() );
			vo.username = client.getAttribute( UserVO.USERNAME );
			vo.client = client;
			
			// generate generic username
			if ( vo.username == null )
			{
				// XXX: get this from a constant
				vo.username = "user" + vo.id;
			}
			
			return vo;
		}
		
        /**
		 * Create and watch rooms.
		 * 
		 * @param rooms
		 */		
		override public function createRooms( rooms:Vector.<BaseRoom> ):void
		{
			_rooms = rooms;
			
			var room:BaseRoom;
			for each ( room in _rooms )
			{
				// create room
				room.create( this );
			}
			
			watchRooms();
		}
        
        /**
         * Create a new union room.
         * 
         * @param id
         * @param settings
         * @param attrs
         * @param modules
         * @return 
         */        
        override public function createRoom( id:String, settings:*, attrs:*, modules:* ):*
        {
        	return roomManager.createRoom( id, settings, attrs, modules );
        }
        
        /**
		 * @inheritDoc
		 */		
		override public function watchRooms():void
		{
			// watch for rooms
			var ids:Vector.<BaseRoom> = new Vector.<BaseRoom>();
			for each ( var room:BaseRoom in _rooms )
			{
				if ( room.watch )
				{
					ids.push( room );
				}
			}
			
			var commonRoomQualifier:String = StringUtil.replace( "%s.*",
												RoomUtils.getRoomsQualifiers( ids ));
			
			roomManager.watchForRooms( commonRoomQualifier );
		}
        
        /**
         * @inheritDoc 
         */        
        override public function addServerMessageListener( type:String, method:Function,
        												   forRoomIDs:Array=null ):Boolean
        {
        	var result:Boolean = false;
        	
        	if ( type )
        	{
        		if ( !messageManager.hasMessageListener( type, method ))
        		{
					result = messageManager.addMessageListener( type, method, forRoomIDs );
        		}
        	}
        	
        	if ( result )
        	{
        		trace("addServerMessageListener - type: " + type + ", method: " + method );
        	}
        	
        	return result;
        }
        
        /**
         * @inheritDoc 
         */             
        override public function removeServerMessageListener( type:String, method:Function ):Boolean
        {
        	var result:Boolean = false;
        	
        	if ( type )
        	{
        		if ( messageManager.hasMessageListener( type, method ))
        		{
					result = messageManager.removeMessageListener( type, method );
        		}
        	}
        	
        	return result;
        }
        
        /**
         * @private
         * @param message		The name of the message to send.
         * @param forRoomIDs	The room(s) to which to send the message.
         */		
        override public function sendServerMessage( message:ChatMessage, forRoomIDs:Array=null ) : void
        {
			roomManager.sendMessage( message.type, forRoomIDs,
									 			  message.includeSelf, null,
									 			  message.message );
        }
        
        /**
         * @private
		 * @param name
		 * @return 
		 */		
		override public function getIPByUserName( name:String ):String
		{
			var ip:String;
			var client:IClient;
			var id:String = name.substr( 4 );
			
			if ( id )
			{
				// XXX: remove hardcoded name length
				var poss:Array = [ getClientByAttribute( UserVO.USERNAME, name ),
								   getClientById( id ) ];
				
				for each ( client in poss )
				{
					if ( client )
					{
						// UNION BUG: this only works for own client
						ip = client.getIP();
						break;
					}
				}
			}
			
			return ip;
		}
		
		/**
		 * @private
		 * @param attrName
		 * @param attrValue
		 * @return 
		 */		
		override public function getClientByAttribute( attrName:String,
													   attrValue:String ):*
		{
			return clientManager.getClientByAttribute( attrName, attrValue );
		}
		
		/**
         * @param clientIDs
         * @param attrName
         * @param attrScope
         * @return 
         */        
        override public function getAttributeForClients(clientIDs:Array, attrName:String, attrScope:String):Array
        {
        	return clientManager.getAttributeForClients( clientIDs, attrName, attrScope );
        }
        
		/**
		 * @private
		 * @param id
		 * @return 
		 */		
		override public function getClientById( id:String ):*
		{
			return clientManager.getClient( id );
		}
        
        // ====================================
		// EVENT HANDLERS
		// ====================================

        /**
		 * Triggered when the connection is established and ready for use.
		 *
		 * @param event
		 */
		private function unionConnectionReady( event:ReactorEvent ):void
		{
            if ( event )
            {
			    event.preventDefault();
            }
            
            // listen for room manager events
			roomManager.addEventListener( RoomManagerEvent.ROOM_ADDED, 		roomAddedListener );
			roomManager.addEventListener( RoomManagerEvent.ROOM_REMOVED, 	roomRemovedListener );
			roomManager.addEventListener( RoomManagerEvent.ROOM_COUNT, 		roomCountListener );

			connectionReady();
		}
		
		/**
		 * Triggered when the connection is closed.
		 *
		 * @param event
		 */
		private function unionConnectionClose( event:ReactorEvent ):void
		{
			if ( event )
			{
				event.preventDefault();
			}
			
			connectionClosed();
		}
		
		/**
		 * Event listener triggered when a room is added to the 
         * room manager's room list.
		 *	 
		 * @param event
		 */		
		private function roomAddedListener( event:RoomManagerEvent ):void
		{
			event.preventDefault();
			
			_roomEvt = new BaseRoomEvent( BaseRoomEvent.ROOM_ADDED, event );
			dispatchEvent( _roomEvt );
		}
		
		/**
		 * Event listener triggered when a room is removed from the 
         * room manager's room list.
		 * 
		 * @param event
		 */		
		private function roomRemovedListener( event:RoomManagerEvent ):void
		{
			event.preventDefault();
			
			_roomEvt = new BaseRoomEvent( BaseRoomEvent.ROOM_REMOVED, event );
			dispatchEvent( _roomEvt );
		}
		
		/**
		 * Event listener triggered when the number of rooms has changed.
		 * 
		 * @param event
		 */		
		private function roomCountListener( event:RoomManagerEvent ):void
		{
			event.preventDefault();
			
			_roomEvt = new BaseRoomEvent( BaseRoomEvent.ROOM_COUNT, event );
			dispatchEvent( _roomEvt );
		}
		
	}
}