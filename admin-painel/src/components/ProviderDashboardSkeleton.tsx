// src/components/ProviderDashboardSkeleton.tsx
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"

export function ProviderDashboardSkeleton() {
  return (
    <div className="flex flex-col gap-6">
      {/* Título da Página */}
      <Skeleton className="h-9 w-[250px]" />
      
      {/* Card de Estatísticas */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <Skeleton className="h-4 w-[180px]" />
            <Skeleton className="h-4 w-4" />
          </CardHeader>
          <CardContent>
            <Skeleton className="h-8 w-[50px]" />
          </CardContent>
        </Card>
      </div>

      {/* Card do Gráfico */}
      <Card>
        <CardHeader>
          <Skeleton className="h-6 w-[300px]" />
          <Skeleton className="h-4 w-[250px] mt-2" />
        </CardHeader>
        <CardContent>
          <div className="flex justify-center items-center h-[350px]">
            <Skeleton className="h-full w-full" />
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
