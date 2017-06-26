package zen.physics.test
{
    import zen.physics.colliders.Collider;
    
    import zen.physics.Contact;
    import zen.physics.*;

    public class NullCollision implements ICollision 
    {


        public function test(collider0:Collider, collider1:Collider, collisions:Vector.<Contact>, collisionCount:int):int
        {
            return (collisionCount);
        }


    }
}

