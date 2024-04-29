using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "meshListContainer", menuName = "Glints/Create Mesh List Container", order = 1)]
public class MeshListContainer : ScriptableObject
{
    [SerializeField] private List<Mesh> meshes = new();

    public List<Mesh> GetMeshes()
    {
        return meshes;
    }
}