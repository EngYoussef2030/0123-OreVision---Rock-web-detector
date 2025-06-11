using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
namespace Graduation_Project.Models;

public partial class RockInfoContext : DbContext
{
    public RockInfoContext()
    {
    }

    public RockInfoContext(DbContextOptions<RockInfoContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Information> Information { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Information>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Informat__3214EC27AA24940F");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
