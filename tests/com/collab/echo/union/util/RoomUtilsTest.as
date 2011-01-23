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
package com.collab.echo.union.util
{
	import com.collab.echo.core.rooms.BaseRoom;
	
	import org.hamcrest.assertThat;
	import org.hamcrest.collection.arrayWithSize;
	import org.hamcrest.collection.emptyArray;
	import org.hamcrest.object.equalTo;
	
	public class RoomUtilsTest
	{		
		private var rooms	: Vector.<BaseRoom>;
		
		[Before]
		public function setUp():void
		{
			var room:BaseRoom;
			var cnt:int = 0;
			
			rooms = new Vector.<BaseRoom>();
			
			for ( cnt; cnt < 2; cnt++ )
			{
				room = new BaseRoom( "room" + cnt );
				rooms.push( room );
			}
		}
		
		[After]
		public function tearDown():void
		{
			rooms = null;
		}
		
		[Test]
		public function testGetRoomIDs():void
		{
			var ids:Array = RoomUtils.getRoomIDs( rooms );
			var cnt:int = 0;
			
			assertThat( ids, arrayWithSize( 2 ));
			
			for ( cnt; cnt < 2; cnt++ )
			{
				assertThat( ids[cnt], equalTo( "room" + cnt ));
			}
			
			ids = RoomUtils.getRoomIDs( new Vector.<BaseRoom>() );
			
			assertThat( ids, emptyArray() );
		}
		
		[Test]
		[Ignore]
		public function testGetRoomsQualifiers():void
		{
		}
	}
}