#include <g5_typo.h>

void dfs(int u,int n,int adj[][100],int vis[])
{
    int p;
    vis[u] = 1;
    g5_printf("%d : ",u);
    for(p=0;p<n;p++)
    {
        if( adj[u][p] == 1 )
        {
            if( vis[p] == 1 );
            else
            {
                dfs(p,n,adj,vis);
            }
        }
    }
}

int main()
{
    int adj[100][100];
    int n,i,j,m,u,v;
    int vis[100];
    g5_printf("Enter no. of vertices : ");
    g5_scanf("%d",&n);
    for(i=0;i<n;i++)
    {
        vis[i] = 0;
        for(j=0;j<n;j++)
        {
            adj[i][j] = 0;
        }
    }
    g5_printf("Enter no. of edges : ");
    g5_scanf("%d",&m);
    g5_printf("Enter %d edges in form of %d end-pts of edges\n",m,m*2);
    for(i=0;i<m;i++)
    {
        g5_scanf("%d",&u);
        g5_scanf("%d",&v);
        adj[u][v] = 1;
        adj[v][u] = 1;
    }
    g5_printf("done\n");
    for(i=0;i<n;i++)
    {
        if( vis[i] == 0 )
        {
            dfs(i,n,adj,vis);
        }
    }
    g5_printf("\n");
    return 0;

}