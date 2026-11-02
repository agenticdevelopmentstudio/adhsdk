from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.persona_service_model_type_1 import PersonaServiceModelType1


T = TypeVar("T", bound="ProviderTemplateVerifyResult")


@_attrs_define
class ProviderTemplateVerifyResult:
    """
    Attributes:
        ok (bool):
        models (list[PersonaServiceModelType1 | str] | Unset):
        error (str | Unset):
    """

    ok: bool
    models: list[PersonaServiceModelType1 | str] | Unset = UNSET
    error: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.persona_service_model_type_1 import PersonaServiceModelType1

        ok = self.ok

        models: list[dict[str, Any] | str] | Unset = UNSET
        if not isinstance(self.models, Unset):
            models = []
            for models_item_data in self.models:
                models_item: dict[str, Any] | str
                if isinstance(models_item_data, PersonaServiceModelType1):
                    models_item = models_item_data.to_dict()
                else:
                    models_item = models_item_data
                models.append(models_item)

        error = self.error

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ok": ok,
            }
        )
        if models is not UNSET:
            field_dict["models"] = models
        if error is not UNSET:
            field_dict["error"] = error

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.persona_service_model_type_1 import PersonaServiceModelType1

        d = dict(src_dict)
        ok = d.pop("ok")

        _models = d.pop("models", UNSET)
        models: list[PersonaServiceModelType1 | str] | Unset = UNSET
        if _models is not UNSET:
            models = []
            for models_item_data in _models:

                def _parse_models_item(data: object) -> PersonaServiceModelType1 | str:
                    try:
                        if not isinstance(data, dict):
                            raise TypeError()
                        componentsschemas_persona_service_model_type_1 = (
                            PersonaServiceModelType1.from_dict(data)
                        )

                        return componentsschemas_persona_service_model_type_1
                    except (TypeError, ValueError, AttributeError, KeyError):
                        pass
                    return cast(PersonaServiceModelType1 | str, data)

                models_item = _parse_models_item(models_item_data)

                models.append(models_item)

        error = d.pop("error", UNSET)

        provider_template_verify_result = cls(
            ok=ok,
            models=models,
            error=error,
        )

        provider_template_verify_result.additional_properties = d
        return provider_template_verify_result

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
