// src/components/DashboardSkeleton.tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

export function DashboardSkeleton() {
  return (
    <div className="flex flex-col gap-6">
      {/* Cards de Stats Skeleton */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, index) => (
          <Card key={index}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <Skeleton className="h-4 w-[150px]" />
              <Skeleton className="h-4 w-4" />
            </CardHeader>
            <CardContent>
              <Skeleton className="h-8 w-[50px]" />
            </CardContent>
          </Card>
        ))}
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Gráfico Skeleton */}
        <Card>
          <CardHeader>
              <Skeleton className="h-6 w-[250px]" />
          </CardHeader>
          <CardContent>
              <div className="flex justify-center items-center h-[350px]">
                  <Skeleton className="h-full w-full" />
              </div>
          </CardContent>
        </Card>
        
        {/* Tabela de Tickets Recentes Skeleton */}
        <Card>
          <CardHeader>
            <CardTitle><Skeleton className="h-6 w-[300px]" /></CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead><Skeleton className="h-5 w-[100px]" /></TableHead>
                  <TableHead><Skeleton className="h-5 w-[150px]" /></TableHead>
                  <TableHead><Skeleton className="h-5 w-[120px]" /></TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {Array.from({ length: 5 }).map((_, index) => (
                  <TableRow key={index}>
                    <TableCell><Skeleton className="h-4 w-full" /></TableCell>
                    <TableCell><Skeleton className="h-4 w-full" /></TableCell>
                    <TableCell><Skeleton className="h-4 w-full" /></TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
