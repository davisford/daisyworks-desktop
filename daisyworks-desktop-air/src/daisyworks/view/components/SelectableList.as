package daisyworks.view.components
{
	import flash.events.MouseEvent;
	
	import mx.core.IVisualElement;
	
	import spark.components.List;
	
	public class SelectableList extends List
	{
		public function SelectableList()
		{
			super();
			allowMultipleSelection = true;
		}
		
		override protected function item_mouseDownHandler(event:MouseEvent):void
		{
			var newIndex:Number = dataGroup.getElementIndex(event.currentTarget as IVisualElement);
			// always assume the Ctrl key is pressed by setting the third param of calculateSelectedIndices() to true
			selectedIndices = calculateSelectedIndices(newIndex, event.shiftKey, true);
		}
	}
}