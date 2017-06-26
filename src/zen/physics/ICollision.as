package zen.physics
{
    import zen.physics.colliders.Collider;
    

    public interface ICollision 
    {

        function test(_arg1:Collider, _arg2:Collider, _arg3:Vector.<Contact>, _arg4:int):int;

    }
}

