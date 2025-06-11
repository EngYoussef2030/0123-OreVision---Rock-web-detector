using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Mvc.ModelBinding.Validation;
using Microsoft.EntityFrameworkCore;

namespace Graduation_Project.Models;

public partial class Information
{
    [Key]
    [Column("ID")]
    public int Id { get; set; }

    [Column("name")]
    [StringLength(15)]
    [Unicode(false)]
    public string? Name { get; set; }
    [NotMapped]
    public string? DetectedClasses { get; set; }

    [StringLength(15)]
    [Unicode(false)]
    public string? ChemicalFormula { get; set; }

    [StringLength(15)]
    [Unicode(false)]
    public string? Color { get; set; }

    public double? Density { get; set; }

    public double? Hardness { get; set; }

    [NotMapped]
    [ValidateNever]
    public string? ImagePath { get; set; }

    [NotMapped]
    [ValidateNever]
    public IFormFile? ImageFile { get; set; }
    [NotMapped]
    public string? ResultImagePath { get; set; }
    public string? GeologicalOrigin  { get; set; }
    public string? IndustrialUse { get; set; }
    public string? HistoricalContext { get; set; }
}
