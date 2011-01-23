/*
Echo project.

Copyright (C) 2011 Collab

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
	import com.collab.echo.events.BaseConnectionEvent;
	import com.collab.echo.events.BaseRoomEvent;
	import com.collab.echo.model.UserVO;
	import com.collab.echo.union.net.UnionConnection;
	
	import net.user1.reactor.Status;
	
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	import org.hamcrest.assertThat;
	import org.hamcrest.collection.arrayWithSize;
	import org.hamcrest.collection.emptyArray;
	import org.hamcrest.core.anyOf;
	import org.hamcrest.object.equalTo;
	import org.hamcrest.object.notNullValue;
	import org.hamcrest.object.nullValue;
	
	public class UnionRoomTest
	{	
		private var conn		: UnionConnection;
		private var room		: UnionRoom;
		private var roomName	: String;
		private var host		: String = "localhost";
		private var port		: int = 9110;
		
		[Before]
		public function setUp():void
		{
			roomName = "test_room"
			room = new UnionRoom( roomName );
			conn = new UnionConnection( host, port );
		}
		
		[After]
		public function tearDown():void
		{
			room = null;
			if ( conn )
			{
				if ( conn.connected )
				{
					conn.disconnect();
				}
			}
			conn = null;
		}
		
		protected function connect( successHandler:Function=null ):void
		{
			conn.addEventListener( BaseConnectionEvent.CONNECTION_SUCCESS, 
				Async.asyncHandler( this, successHandler, 1000,
					null, handleEventNeverOccurred ), 
				false, 0, true );
			
			conn.connect();
		}
		
		protected function handleEventNeverOccurred( passThroughData:Object ):void
		{
			Assert.fail('Pending Event Never Occurred');
		}
		
		[Test]
		public function testUnionRoom():void
		{
			assertThat( room.id, equalTo( roomName ));
			assertThat( room.autoJoin, equalTo( false ));
			assertThat( room.watch, equalTo( true ));
			assertThat( room.joined, equalTo( false ));
		}
		
		[Test( async )]
		public function testCreate():void
		{
			connect( create );
		}
		
		protected function create( event:BaseConnectionEvent,
								   passThroughData:Object ):void
		{
			conn.addEventListener( BaseRoomEvent.ROOM_ADDED_RESULT, 
				Async.asyncHandler( this, verifyCreate, 1000,
									null, handleEventNeverOccurred ), 
									false, 0, true );
			
			room.create( conn );
		}
		
		protected function verifyCreate( event:BaseRoomEvent,
										 passThroughData:Object ):void
		{
			assertThat( event.data.getStatus(), anyOf(
						equalTo( Status.ROOM_EXISTS ),
						equalTo( Status.SUCCESS )
			));
		}
		
		[Test( async )]
		public function testJoin():void
		{
			connect( join );
		}
		
		protected function join( event:BaseConnectionEvent,
								 passThroughData:Object ):void
		{
			room.addEventListener( BaseRoomEvent.JOIN_RESULT, 
				Async.asyncHandler( this, verifyJoin, 1000,
									null, handleEventNeverOccurred ), 
									false, 0, true );
			// connect and join room
			room.create( conn );
			room.join();
		}
		
		protected function verifyJoin( event:BaseRoomEvent,
									   passThroughData:Object ):void
		{
			assertThat( event.data.getStatus(), equalTo( Status.SUCCESS ));
			assertThat( room.joined, equalTo( true ));
		}
		
		[Test( async )]
		public function testLeave():void
		{
			connect( leave );
		}
		
		protected function leave( event:BaseConnectionEvent,
								  passThroughData:Object ):void
		{
			room.addEventListener( BaseRoomEvent.JOIN_RESULT, 
				Async.asyncHandler( this, verifyLeave1, 1000,
									null, handleEventNeverOccurred ), 
									false, 0, true );
			
			// connect and join room
			room.create( conn );
			room.join();
		}
		
		protected function verifyLeave1( event:BaseRoomEvent,
										passThroughData:Object ):void
		{
			assertThat( event.data.getStatus(), equalTo( Status.SUCCESS ));
			
			room.addEventListener( BaseRoomEvent.LEAVE_RESULT, 
				Async.asyncHandler( this, verifyLeave2, 1000,
									null, handleEventNeverOccurred ), 
									false, 0, true );
			
			// leave room
			room.leave();
		}
		
		protected function verifyLeave2( event:BaseRoomEvent,
									   passThroughData:Object ):void
		{
			assertThat( event.data.getStatus(), equalTo( Status.SUCCESS ));
			assertThat( room.joined, equalTo( false ));
		}
		
		[Test]
		[Ignore]
		public function testGetAnonymousClientIdByUsername():void
		{
		}
		
		[Test]
		[Ignore]
		public function testGetAttributeForClients():void
		{
		}
		
		[Test]
		[Ignore]
		public function testGetClientByAttribute():void
		{
		}
		
		[Test( async )]
		public function testGetClientById():void
		{
			connect( getClientById );
		}
		
		protected function getClientById( event:BaseConnectionEvent,
										  passThroughData:Object ):void
		{
			room.create( conn );
			
			assertThat( room.getClientById( conn.self.getClientID() ),
					    equalTo( conn.self ));
		}
		
		[Test( async )]
		public function testGetClientId():void
		{
			connect( getClientId );
		}
		
		protected function getClientId( event:BaseConnectionEvent,
								        passThroughData:Object ):void
		{
			room.create( conn );
			
			assertThat( room.getClientId(), equalTo(
						conn.self.getClientID() ));
		}
		
		[Test]
		[Ignore]
		public function testGetClientIdByUsername():void
		{
		}
		
		[Test( async )]
		public function testGetIPByUserName():void
		{
			connect( getIPByUserName );
		}
		
		protected function getIPByUserName( event:BaseConnectionEvent,
										    passThroughData:Object ):void
		{
			room.create( conn );
			
			var name:String = "user" + conn.self.getClientID();
			
			assertThat( room.getIPByUserName( name ), equalTo(
						"0:0:0:0:0:0:0:1"));
		}
		
		[Test( async )]
		public function testGetOccupantIDs():void
		{
			connect( getOccupantIDs );
		}
		
		protected function getOccupantIDs( event:BaseConnectionEvent,
										   passThroughData:Object ):void
		{
			room.create( conn );
			
			assertThat( room.getOccupantIDs(), emptyArray() );
			
			room.addEventListener( BaseRoomEvent.JOIN_RESULT, 
				Async.asyncHandler( this, verifyGetOccupantIDs, 1000,
									null, handleEventNeverOccurred ), 
									false, 0, true );
			room.join();
		}
		
		protected function verifyGetOccupantIDs( event:BaseRoomEvent,
									   			 passThroughData:Object ):void
		{
			var users:Array = room.getOccupantIDs();
			
			assertThat( users, arrayWithSize( 1 ));
			assertThat( users[0], equalTo(
						conn.self.getClientID() ));
		}
		
		[Test( async )]
		public function testGetOccupants():void
		{
			connect( getOccupants );
		}
		
		protected function getOccupants( event:BaseConnectionEvent,
										 passThroughData:Object ):void
		{
			room.create( conn );
			
			assertThat( room.getOccupants(), emptyArray() );
			
			room.addEventListener( BaseRoomEvent.JOIN_RESULT, 
				Async.asyncHandler( this, verifyGetOccupants, 1000,
									null, handleEventNeverOccurred ), 
									false, 0, true );
			room.join();
		}
		
		protected function verifyGetOccupants( event:BaseRoomEvent,
											   passThroughData:Object ):void
		{
			var users:Array = room.getOccupants();
			
			assertThat( users, arrayWithSize( 1 ));
			assertThat( users[0], equalTo( conn.self ));
		}
		
		[Test]
		public function testParseUser_disconnected():void
		{
			var user:UserVO = room.parseUser( conn.self );
			
			assertThat( user, nullValue() );
		}
		
		[Test( async )]
		public function testParseUser_connected():void
		{
			connect( testParseUser );
		}
		
		protected function testParseUser( event:BaseConnectionEvent,
										  passThroughData:Object ):void
		{
			room.create( conn );
			
			var user:UserVO = room.parseUser( conn.self );
			
			assertThat( user, notNullValue() );
			assertThat( user.client, equalTo( conn.self ));
		}
		
		[Test]
		[Ignore]
		public function testSendMessage():void
		{
		}
		
		[Test]
		[Ignore]
		public function testAddMessageListener():void
		{
		}
		
		[Test]
		[Ignore]
		public function testRemoveMessageListener():void
		{
		}
		
		[Test]
		public function testToString():void
		{
			var msg:String = StringUtil.replace( "<UnionRoom id='%s' />", roomName );
			
			assertThat( room.toString(), equalTo( msg ));
		}
	}
}