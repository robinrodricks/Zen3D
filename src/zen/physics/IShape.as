package zen.physics
{
    import flash.geom.Vector3D;
    import zen.physics.test.AxisInfo;
    

    public interface IShape 
    {

        function project(_arg1:Vector3D, _arg2:AxisInfo):void;
        function getSupportPoints(_arg1:Vector3D, _arg2:Vector.<Vector3D>):int;

    }
}

