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
package com.collab.echo.union.util
{
	import com.collab.echo.core.rooms.BaseRoom;
	
	import net.user1.reactor.RoomIDParser;
	
	/**
	 * Room utilities.
	 * 
	 * @author Thijs Triemstra
	 * 
	 * @langversion 3.0
 	 * @playerversion Flash 10
	 */	
	public class RoomUtils
	{
		/**
		 * Get list of room id's.
		 * 
		 * @param rooms
		 * @param BaseRoom
		 * @return 
		 */		
		public static function getRoomIDs( rooms:Vector.<BaseRoom> ):Array
		{
			var ids:Array = [];
			
			for each ( var room:BaseRoom in rooms )
			{
				ids.push( room.id );
			}
			
			return ids;
		}
		
		/**
		 * Get common room qualifers.
		 * 
		 * @param rooms
		 * @param BaseRoom
		 * @return 
		 */		
		public static function getRoomsQualifiers( rooms:Vector.<BaseRoom> ):String
		{
			var ids:Array = [];
			var qs:Array = [];
			var id:String;
			
			for each ( var room:BaseRoom in rooms )
			{
				id = RoomIDParser.getQualifier( room.id );
				qs.push( id );
			}
			
			return qs[ 0 ];
		}

	}
}