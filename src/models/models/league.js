var League = Backbone.Model.extend(
{
  //instance properties
  
  defaults : {
	  imageUrl : null,
	  abbreviation : null,
	  name: null
  },
  
  drawsPossible : function() {
	  if (this.get("abbreviation")=="EPL")
  	  return true;
    return false;
  }

},
{

  //class properties
  
 
}
);
