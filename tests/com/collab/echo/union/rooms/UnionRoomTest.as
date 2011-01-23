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
	import com.collab.echo.union.net.UnionConnection;
	
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	import org.hamcrest.assertThat;
	import org.hamcrest.object.equalTo;
	
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
			conn = new UnionConnection(host, port);
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
		
		[Test]
		public function testUnionRoom():void
		{
			assertThat( room.id, equalTo( roomName ));
			assertThat( room.autoJoin, equalTo( false ));
			assertThat( room.watch, equalTo( true ));
		}
		
		[Test( async )]
		public function testJoin():void
		{
			connect( join );
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
		
		protected function join( event:BaseConnectionEvent,
								 passThroughData:Object ):void
		{
		}
		
		[Test]
		[Ignore]
		public function testAddMessageListener():void
		{
		}
		
		[Test]
		[Ignore]
		public function testCreate():void
		{
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
		
		[Test]
		[Ignore]
		public function testGetClientById():void
		{
		}
		
		[Test]
		[Ignore]
		public function testGetClientId():void
		{
		}
		
		[Test]
		[Ignore]
		public function testGetClientIdByUsername():void
		{
		}
		
		[Test]
		[Ignore]
		public function testGetIPByUserName():void
		{
		}
		
		[Test]
		[Ignore]
		public function testGetOccupantIDs():void
		{
		}
		
		[Test]
		[Ignore]
		public function testGetOccupants():void
		{
		}
		
		[Test]
		[Ignore]
		public function testLeave():void
		{
		}
		
		[Test]
		[Ignore]
		public function testParseUser():void
		{
		}
		
		[Test]
		[Ignore]
		public function testRemoveMessageListener():void
		{
		}
		
		[Test]
		[Ignore]
		public function testSendMessage():void
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