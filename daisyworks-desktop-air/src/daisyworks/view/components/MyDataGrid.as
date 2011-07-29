package daisyworks.view.components
{
	import spark.components.DataGrid;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.collections.ISort;
	import mx.collections.ISortField;
	import mx.core.EventPriority;
	import mx.core.IFactory;
	import mx.core.IIMESupport;
	import mx.core.LayoutDirection;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	import mx.managers.CursorManager;
	import mx.managers.CursorManagerPriority;
	import mx.managers.IFocusManagerComponent;
	import mx.styles.AdvancedStyleClient;
	
	import spark.collections.Sort;
	import spark.components.gridClasses.CellPosition;
	import spark.components.gridClasses.CellRegion;
	import spark.components.gridClasses.DataGridEditor;
	import spark.components.gridClasses.GridColumn;
	import spark.components.gridClasses.GridLayout;
	import spark.components.gridClasses.GridSelection;
	import spark.components.gridClasses.GridSelectionMode;
	import spark.components.gridClasses.GridSortField;
	import spark.components.gridClasses.IDataGridElement;
	import spark.components.gridClasses.IGridItemEditor;
	import spark.components.supportClasses.SkinnableContainerBase;
	import spark.core.NavigationUnit;
	import spark.events.GridCaretEvent;
	import spark.events.GridEvent;
	import spark.events.GridSelectionEvent;
	import spark.events.GridSelectionEventKind;
	import spark.events.GridSortEvent;
	
	/**
	 * What a horrible PITA.
	 * 
	 * @see http://stackoverflow.com/questions/5764863/flex-4-5-spark-datagrid-detect-column-clicked-in-selectionchange-handler
	 * 
	 * All this just to avoid selecting a whole row when the user checks a box in the DataGrid.
	 * Seems like this really is a bug in <s:DataGrid>.  The change is on line 77
	 * 
	 * const columnIndex:int = event.columnIndex
	 * 
	 * All the other code I had to copy in b/c it was referenced and private or mx_internal
	 * 
	 */
	public class MyDataGrid extends DataGrid
	{
		public function MyDataGrid()
		{
			//TODO: implement function
			super();
		}
		
		/**
		 *  @private
		 */
		override protected function grid_mouseDownHandler(event:GridEvent):void
		{
			if (event.isDefaultPrevented())
				return;
			
			const isCellSelection:Boolean = isCellSelectionMode();
			
			const rowIndex:int = event.rowIndex;
			const columnIndex:int = event.columnIndex;
			
			// Clicked on empty place in grid.  Don't change selection or caret
			// position.
			if (rowIndex == -1 || isCellSelection && columnIndex == -1)
				return;
			
			if (event.ctrlKey)
			{
				// ctrl-click toggles the selection and updates caret and anchor.
				if (!toggleSelection(rowIndex, columnIndex))
					return;
				
				grid.anchorRowIndex = rowIndex;
				grid.anchorColumnIndex = columnIndex;
			}
			else if (event.shiftKey)
			{
				// shift-click extends the selection and updates the caret.
				if  (grid.selectionMode == GridSelectionMode.MULTIPLE_ROWS || 
					grid.selectionMode == GridSelectionMode.MULTIPLE_CELLS)
				{    
					if (!extendSelection(rowIndex, columnIndex))
						return;
				}
			}
			else
			{
				// click sets the selection and updates the caret and anchor 
				// positions.
				setSelectionAnchorCaret(rowIndex, columnIndex);
			}
		}
		
		private function setSelectionAnchorCaret(rowIndex:int, columnIndex:int):Boolean
		{
			// click sets the selection and updates the caret and anchor 
			// positions.
			var success:Boolean;
			if (isRowSelectionMode())
			{
				// Select the row.
				success = commitInteractiveSelection(
					GridSelectionEventKind.SET_ROW, 
					rowIndex, columnIndex);
			}
			else if (isCellSelectionMode())
			{
				// Select the cell.
				success = commitInteractiveSelection(
					GridSelectionEventKind.SET_CELL, 
					rowIndex, columnIndex);
			}
			
			// Update the caret and anchor positions unless cancelled.
			if (success)
			{
				commitCaretPosition(rowIndex, columnIndex);
				grid.anchorRowIndex = rowIndex;
				grid.anchorColumnIndex = columnIndex; 
			}    
			
			return success;
		}
		
		private function isAnchorSet():Boolean
		{
			if (!grid)
				return false;
			
			if (isRowSelectionMode())
				return grid.anchorRowIndex != -1;
			else
				return grid.anchorRowIndex != -1 && grid.anchorRowIndex != -1;
		}
		
		private function extendSelection(caretRowIndex:int, 
										 caretColumnIndex:int):Boolean
		{
			if (!isAnchorSet())
				return false;
			
			const startRowIndex:int = Math.min(grid.anchorRowIndex, caretRowIndex);
			const endRowIndex:int = Math.max(grid.anchorRowIndex, caretRowIndex);
			var success:Boolean;
			
			if (selectionMode == GridSelectionMode.MULTIPLE_ROWS)
			{
				success = commitInteractiveSelection(
					GridSelectionEventKind.SET_ROWS,
					startRowIndex, -1,
					endRowIndex - startRowIndex + 1, 0);
			}
			else if (selectionMode == GridSelectionMode.SINGLE_ROW)
			{
				// Can't extend the selection so move it to the caret position.
				success = commitInteractiveSelection(
					GridSelectionEventKind.SET_ROW, caretRowIndex, -1, 1, 0);                
			}
			else if (selectionMode == GridSelectionMode.MULTIPLE_CELLS)
			{
				const rowCount:int = endRowIndex - startRowIndex + 1;
				const startColumnIndex:int = 
					Math.min(grid.anchorColumnIndex, caretColumnIndex);
				const endColumnIndex:int = 
					Math.max(grid.anchorColumnIndex, caretColumnIndex); 
				const columnCount:int = endColumnIndex - startColumnIndex + 1;
				
				success = commitInteractiveSelection(
					GridSelectionEventKind.SET_CELL_REGION, 
					startRowIndex, startColumnIndex,
					rowCount, columnCount);
			}            
			else if (selectionMode == GridSelectionMode.SINGLE_CELL)
			{
				// Can't extend the selection so move it to the caret position.
				success = commitInteractiveSelection(
					GridSelectionEventKind.SET_CELL, 
					caretRowIndex, caretColumnIndex, 1, 1);                
			}
			
			// Update the caret.
			if (success)
				commitCaretPosition(caretRowIndex, caretColumnIndex);
			
			return success;
		}
		
		private function isCellSelectionMode():Boolean
		{
			const mode:String = selectionMode;        
			return mode == GridSelectionMode.SINGLE_CELL || mode == GridSelectionMode.MULTIPLE_CELLS;
		} 
		
		private function isRowSelectionMode():Boolean
		{
			const mode:String = selectionMode;
			return mode == GridSelectionMode.SINGLE_ROW || mode == GridSelectionMode.MULTIPLE_ROWS;
		}
		
		private function toggleSelection(rowIndex:int, columnIndex:int):Boolean
		{
			var kind:String;
			
			if (isRowSelectionMode())
			{ 
				if (grid.selectionContainsIndex(rowIndex))
					kind = GridSelectionEventKind.REMOVE_ROW;
				else if (selectionMode == GridSelectionMode.MULTIPLE_ROWS)
					kind = GridSelectionEventKind.ADD_ROW;
				else
					kind = GridSelectionEventKind.SET_ROW;
				
			}
			else if (isCellSelectionMode())
			{
				if (grid.selectionContainsCell(rowIndex, columnIndex))
					kind = GridSelectionEventKind.REMOVE_CELL;
				else if (selectionMode == GridSelectionMode.MULTIPLE_CELLS)
					kind = GridSelectionEventKind.ADD_CELL;
				else
					kind = GridSelectionEventKind.SET_CELL;
			}
			
			var success:Boolean = 
				commitInteractiveSelection(kind, rowIndex, columnIndex);
			
			// Update the caret if the selection was not cancelled.
			if (success)
				commitCaretPosition(rowIndex, columnIndex);
			
			return success;
		}
	}
}