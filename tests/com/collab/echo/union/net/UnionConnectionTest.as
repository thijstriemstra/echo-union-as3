/*
Cabin project.

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
package com.collab.echo.union.net
{
	import com.collab.echo.core.rooms.BaseRoom;
	import com.collab.echo.events.BaseConnectionEvent;
	import com.collab.echo.model.UserVO;
	
	import net.user1.reactor.IClient;
	
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	import org.hamcrest.assertThat;
	import org.hamcrest.core.isA;
	import org.hamcrest.object.equalTo;
	import org.hamcrest.object.notNullValue;
	
	public class UnionConnectionTest
	{		
		private var conn	: UnionConnection;
		private var host	: String = "localhost";
		private var port	: int = 9110;
		
		[Before]
		public function setUp():void
		{
			conn = new UnionConnection(host, port);
		}
		
		[After]
		public function tearDown():void
		{
			if ( conn )
			{
				if ( conn.connected )
				{
					conn.disconnect();
				}
			}
			conn = null;
		}
		
		[Test]
		public function testUnionConnection():void
		{
		}
		
		protected function handleEventNeverOccurred( passThroughData:Object ):void
		{
			Assert.fail('Pending Event Never Occurred');
		}
		
		[Test( async )]
		public function testConnect():void
		{
			assertThat( conn.connected, equalTo( false ));
			
			conn.addEventListener( BaseConnectionEvent.CONNECTING, 
				Async.asyncHandler( this, null, 1000,
									null, handleEventNeverOccurred ), 
									false, 0, true );
			
			connect( verifyConnectionSuccess );
		}
		
		protected function connect( successHandler:Function=null ):void
		{
			conn.addEventListener( BaseConnectionEvent.CONNECTION_SUCCESS, 
				Async.asyncHandler( this, successHandler, 1000,
									null, handleEventNeverOccurred ), 
									false, 0, true );
			
			conn.connect();
		}
		
		protected function verifyConnectionSuccess( event:BaseConnectionEvent,
													passThroughData:Object ):void
		{
			assertThat( conn.connected, equalTo( true ));
		}
		
		[Test( async )]
		public function testDisconnect():void
		{
			// first connect, do disconnect in event success handler
			connect( disconnect );
		}
		
		protected function disconnect( event:BaseConnectionEvent,
									   passThroughData:Object ):void
		{
			assertThat( conn.connected, equalTo( true ));
			
			conn.addEventListener( BaseConnectionEvent.DISCONNECTING, 
				Async.asyncHandler( this, null, 1000,
									null, handleEventNeverOccurred ), 
									false, 0, true );

			conn.addEventListener( BaseConnectionEvent.CONNECTION_CLOSED, 
				Async.asyncHandler( this, verifyConnectionClosed, 1000,
									null, handleEventNeverOccurred ), 
									false, 0, true );
			
			conn.disconnect();
		}
		
		protected function verifyConnectionClosed( event:BaseConnectionEvent,
												   passThroughData:Object ):void
		{
			assertThat( conn.connected, equalTo( false ));
		}
		
		[Test( async )]
		public function testCreateRoom():void
		{
			connect( createRoom );
		}
		
		protected function createRoom( event:BaseConnectionEvent,
									   passThroughData:Object ):void
		{
			var roomName:String = "room" + int(Math.random() * 1000).toFixed();
			conn.createRoom( roomName, null, null, null );
		}
		
		[Test( async )]
		public function testCreateRooms():void
		{
			connect( createRooms );
		}
		
		protected function createRooms( event:BaseConnectionEvent,
										passThroughData:Object ):void
		{
			var rooms:Vector.<BaseRoom> = new Vector.<BaseRoom>();
			var room:BaseRoom;
			var cnt:int = 0;
			
			for ( cnt; cnt < 3; cnt++ )
			{
				room = new BaseRoom( "room" + cnt );
				rooms.push( room );
			}
			
			conn.createRooms( rooms );
		}
		
		[Test( async )]
		public function testWatchRooms():void
		{
			connect( watchRooms );
		}
		
		protected function watchRooms( event:BaseConnectionEvent,
									   passThroughData:Object ):void
		{
			conn.watchRooms();
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
		public function testGetIPByUserName():void
		{
			connect( getIPByUserName );
		}
		
		protected function getIPByUserName( event:BaseConnectionEvent,
									        passThroughData:Object ):void
		{
			var name:String = "user" + conn.self.getClientID();
			var ip:String = conn.getIPByUserName( name );

			assertThat( ip, equalTo( "0:0:0:0:0:0:0:1" ));
		}
		
		[Test( async )]
		public function testGetClientById():void
		{
			connect( getClientById );
		}
		
		protected function getClientById( event:BaseConnectionEvent,
									      passThroughData:Object ):void
		{
			var client:IClient = conn.getClientById( conn.self.getClientID() );
			
			assertThat( client.getClientID(), equalTo( conn.self.getClientID() ));
		}
		
		[Test( async )]
		public function testParseUser():void
		{
			connect( parseUser );
		}
		
		protected function parseUser( event:BaseConnectionEvent,
									  passThroughData:Object ):void
		{
			var client:IClient = conn.self;
			var user:UserVO = conn.parseUser( client );
			
			assertThat( user, notNullValue() );
			assertThat( user.client, equalTo( client ));
			assertThat( user.username, equalTo( "user" + conn.self.getClientID() ));
		}
		
		[Test( async )]
		public function testGet_self():void
		{
			connect( verifySelf );
		}
		
		protected function verifySelf( event:BaseConnectionEvent,
									   passThroughData:Object ):void
		{
			assertThat( conn.self, isA( IClient ));
			assertThat( conn.self.isSelf(), equalTo( true ));
		}
		
		[Test]
		[Ignore]
		public function testSendServerMessage():void
		{
		}
		
		[Test]
		[Ignore]
		public function testAddServerMessageListener():void
		{
		}
		
		[Test]
		[Ignore]
		public function testRemoveServerMessageListener():void
		{
		}
	}
}