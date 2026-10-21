namespace Nova.__Nombre__.Dominio.Comun;

/// <summary>
/// Objeto sin identidad: vale por lo que contiene (un correo, un monto, un estado).
/// Se escribe como <c>record</c> para que dos iguales sean iguales, y se valida al crearlo.
/// </summary>
public abstract record ObjetoValor;
