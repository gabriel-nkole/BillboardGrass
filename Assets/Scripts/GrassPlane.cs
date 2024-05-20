using UnityEngine;

public class GrassPlane : MonoBehaviour {

    [SerializeField]
    Mesh Mesh;

    [SerializeField]
    Material Mat;

    [SerializeField, Range(1, 600)]
    int Resolution = 11;

    [SerializeField, Range(1, 10)]
    int Density = 1;


    ComputeBuffer argsBuffer;
    private uint[] args = new uint[5] {0, 0, 0, 0, 0};

    void OnEnable() {
        argsBuffer = new ComputeBuffer(5, sizeof(uint), ComputeBufferType.IndirectArguments);

        args[0] = Mesh.GetIndexCount(0);
        args[1] = (uint)(Resolution * Resolution);
        args[2] = Mesh.GetIndexStart(0);
        args[3] = Mesh.GetBaseVertex(0);
        argsBuffer.SetData(args);

        Mat.SetFloat("_Resolution", Resolution);
        Mat.SetFloat("_Density", Density);
        Matrix4x4 parentToWorld = this.transform.localToWorldMatrix;
        Mat.SetMatrix("_ParentToWorld", parentToWorld);
    }

    void OnDisable() {
        argsBuffer.Release();
        argsBuffer = null;
    }

    void OnValidate() {
        if (argsBuffer != null & enabled) {
            OnDisable();
            OnEnable();
        }
    }

    void Update() {
        if (this.transform.hasChanged) {
            OnValidate();
        }

        MaterialPropertyBlock mpb = new MaterialPropertyBlock();
        mpb.SetFloat("_Angle", 0f);
        Graphics.DrawMeshInstancedIndirect(Mesh, 0, Mat, new Bounds(Vector3.zero, new Vector3(300.0f, 200.0f, 300.0f)), argsBuffer, 0, mpb);

        mpb.SetFloat("_Angle", 45f);
        Graphics.DrawMeshInstancedIndirect(Mesh, 0, Mat, new Bounds(Vector3.zero, new Vector3(300.0f, 200.0f, 300.0f)), argsBuffer, 0, mpb);
        
        mpb.SetFloat("_Angle", -45f);
        Graphics.DrawMeshInstancedIndirect(Mesh, 0, Mat, new Bounds(Vector3.zero, new Vector3(300.0f, 200.0f, 300.0f)), argsBuffer, 0, mpb);
    }
}
