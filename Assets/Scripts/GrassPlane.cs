using UnityEngine;

public class GrassPlane : MonoBehaviour {
    [SerializeField]
    public Mesh Mesh;

    [SerializeField]
    public Material Mat;

    [SerializeField]
    public Texture2D HeightMap;

    [SerializeField, Range(1, 900)]
    public int Resolution = 300;

    [SerializeField, Range(1, 10)]
    public int Density = 1;

    [SerializeField, Range(0, 200)]
    public int DisplacementStrength = 100;


    private ComputeBuffer argsBuffer;
    private ComputeBuffer grassHeightsBuffer;
    private ComputeBuffer matricesBuffer;
    private ComputeBuffer matrices2Buffer;
    private ComputeBuffer matrices3Buffer;
    private uint[] args = new uint[5] {0, 0, 0, 0, 0};


    private const int LOCAL_WORK_GROUPS_X = 8;
    private const int LOCAL_WORK_GROUPS_Y = 8;

    void OnEnable() {
        int threadGroupsX = Mathf.CeilToInt((float)Resolution / (float)LOCAL_WORK_GROUPS_X);
        int threadGroupsY = Mathf.CeilToInt((float)Resolution / (float)LOCAL_WORK_GROUPS_Y);


        argsBuffer = new ComputeBuffer(5, sizeof(uint), ComputeBufferType.IndirectArguments);
        grassHeightsBuffer = new ComputeBuffer(Resolution*Resolution, sizeof(float));
        matricesBuffer = new ComputeBuffer(Resolution*Resolution, sizeof(float) * 16);
        matrices2Buffer = new ComputeBuffer(Resolution*Resolution, sizeof(float) * 16);
        matrices3Buffer = new ComputeBuffer(Resolution*Resolution, sizeof(float) * 16);

        args[0] = Mesh.GetIndexCount(0);
        args[1] = (uint)(Resolution * Resolution);
        args[2] = Mesh.GetIndexStart(0);
        args[3] = Mesh.GetBaseVertex(0);
        argsBuffer.SetData(args);



        ComputeShader Grass_CS = Resources.Load<ComputeShader>("Grass");
        Grass_CS.SetFloat("_Resolution", (float)Resolution);
        Grass_CS.SetFloat("_Density", (float)Density);
        Grass_CS.SetFloat("_DispStrength", (float)DisplacementStrength);


        Grass_CS.SetBuffer(0, "_GrassHeights", grassHeightsBuffer);
        Grass_CS.Dispatch(0, threadGroupsX, threadGroupsY, 1);


        Grass_CS.SetBuffer(1, "_GrassHeights", grassHeightsBuffer);
        Grass_CS.SetTexture(1, "_HeightMap", HeightMap);
        Grass_CS.SetMatrix("_ParentToWorld", this.transform.localToWorldMatrix);

        Grass_CS.SetFloat("_Angle", 0f);
        Grass_CS.SetBuffer(1, "_Matrices", matricesBuffer);
        Grass_CS.Dispatch(1, threadGroupsX, threadGroupsY, 1);

        Grass_CS.SetFloat("_Angle", 45f);
        Grass_CS.SetBuffer(1, "_Matrices", matrices2Buffer);
        Grass_CS.Dispatch(1, threadGroupsX, threadGroupsY, 1);
        
        Grass_CS.SetFloat("_Angle", -45f);
        Grass_CS.SetBuffer(1, "_Matrices", matrices3Buffer);
        Grass_CS.Dispatch(1, threadGroupsX, threadGroupsY, 1);



        Mat.SetFloat("_Resolution", Resolution);
        Mat.SetFloat("_Density", Density);
        Mat.SetFloat("_DispStrength", DisplacementStrength);
        Mat.SetBuffer("_GrassHeights", grassHeightsBuffer);
    }

    void OnDisable() {
        matrices3Buffer.Release();
        matrices3Buffer = null;

        matrices2Buffer.Release();
        matrices2Buffer = null;
        
        matricesBuffer.Release();
        matricesBuffer = null;

        grassHeightsBuffer.Release();
        grassHeightsBuffer = null;

        argsBuffer.Release();
        argsBuffer = null;
    }

    void OnValidate() {
        if (matricesBuffer != null & enabled) {
            OnDisable();
            OnEnable();
        }
    }

    void Update() {
        if (this.transform.hasChanged) {
            OnValidate();
            this.transform.hasChanged = false;
        }

        MaterialPropertyBlock mpb = new MaterialPropertyBlock();

        mpb.SetBuffer("_Matrices", matricesBuffer);
        Graphics.DrawMeshInstancedIndirect(Mesh, 0, Mat, new Bounds(Vector3.zero, new Vector3(300.0f, 200.0f, 300.0f)), argsBuffer, 0, mpb);

        mpb.SetBuffer("_Matrices", matrices2Buffer);
        Graphics.DrawMeshInstancedIndirect(Mesh, 0, Mat, new Bounds(Vector3.zero, new Vector3(300.0f, 200.0f, 300.0f)), argsBuffer, 0, mpb);
        
        mpb.SetBuffer("_Matrices", matrices3Buffer);
        Graphics.DrawMeshInstancedIndirect(Mesh, 0, Mat, new Bounds(Vector3.zero, new Vector3(300.0f, 200.0f, 300.0f)), argsBuffer, 0, mpb);
    }
}