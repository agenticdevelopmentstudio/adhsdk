from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.persona_service_model_type_1 import PersonaServiceModelType1


T = TypeVar("T", bound="PersonaService")


@_attrs_define
class PersonaService:
    """
    Attributes:
        id (str):
        provider_kind (str):
        name (str):
        base_url (str):
        has_api_key (bool):
        connect_status (str):
        models (list[PersonaServiceModelType1 | str]):
        template_id (None | str | Unset):
        connect_error (None | str | Unset):
        last_connected_at (None | str | Unset):
        documentation_url (None | str | Unset):
        status_url (None | str | Unset):
        models_fetched_at (None | str | Unset):
    """

    id: str
    provider_kind: str
    name: str
    base_url: str
    has_api_key: bool
    connect_status: str
    models: list[PersonaServiceModelType1 | str]
    template_id: None | str | Unset = UNSET
    connect_error: None | str | Unset = UNSET
    last_connected_at: None | str | Unset = UNSET
    documentation_url: None | str | Unset = UNSET
    status_url: None | str | Unset = UNSET
    models_fetched_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.persona_service_model_type_1 import PersonaServiceModelType1

        id = self.id

        provider_kind = self.provider_kind

        name = self.name

        base_url = self.base_url

        has_api_key = self.has_api_key

        connect_status = self.connect_status

        models = []
        for models_item_data in self.models:
            models_item: dict[str, Any] | str
            if isinstance(models_item_data, PersonaServiceModelType1):
                models_item = models_item_data.to_dict()
            else:
                models_item = models_item_data
            models.append(models_item)

        template_id: None | str | Unset
        if isinstance(self.template_id, Unset):
            template_id = UNSET
        else:
            template_id = self.template_id

        connect_error: None | str | Unset
        if isinstance(self.connect_error, Unset):
            connect_error = UNSET
        else:
            connect_error = self.connect_error

        last_connected_at: None | str | Unset
        if isinstance(self.last_connected_at, Unset):
            last_connected_at = UNSET
        else:
            last_connected_at = self.last_connected_at

        documentation_url: None | str | Unset
        if isinstance(self.documentation_url, Unset):
            documentation_url = UNSET
        else:
            documentation_url = self.documentation_url

        status_url: None | str | Unset
        if isinstance(self.status_url, Unset):
            status_url = UNSET
        else:
            status_url = self.status_url

        models_fetched_at: None | str | Unset
        if isinstance(self.models_fetched_at, Unset):
            models_fetched_at = UNSET
        else:
            models_fetched_at = self.models_fetched_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "provider_kind": provider_kind,
                "name": name,
                "base_url": base_url,
                "has_api_key": has_api_key,
                "connect_status": connect_status,
                "models": models,
            }
        )
        if template_id is not UNSET:
            field_dict["template_id"] = template_id
        if connect_error is not UNSET:
            field_dict["connect_error"] = connect_error
        if last_connected_at is not UNSET:
            field_dict["last_connected_at"] = last_connected_at
        if documentation_url is not UNSET:
            field_dict["documentation_url"] = documentation_url
        if status_url is not UNSET:
            field_dict["status_url"] = status_url
        if models_fetched_at is not UNSET:
            field_dict["models_fetched_at"] = models_fetched_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.persona_service_model_type_1 import PersonaServiceModelType1

        d = dict(src_dict)
        id = d.pop("id")

        provider_kind = d.pop("provider_kind")

        name = d.pop("name")

        base_url = d.pop("base_url")

        has_api_key = d.pop("has_api_key")

        connect_status = d.pop("connect_status")

        models = []
        _models = d.pop("models")
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

        def _parse_template_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        template_id = _parse_template_id(d.pop("template_id", UNSET))

        def _parse_connect_error(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        connect_error = _parse_connect_error(d.pop("connect_error", UNSET))

        def _parse_last_connected_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_connected_at = _parse_last_connected_at(d.pop("last_connected_at", UNSET))

        def _parse_documentation_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        documentation_url = _parse_documentation_url(d.pop("documentation_url", UNSET))

        def _parse_status_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        status_url = _parse_status_url(d.pop("status_url", UNSET))

        def _parse_models_fetched_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        models_fetched_at = _parse_models_fetched_at(d.pop("models_fetched_at", UNSET))

        persona_service = cls(
            id=id,
            provider_kind=provider_kind,
            name=name,
            base_url=base_url,
            has_api_key=has_api_key,
            connect_status=connect_status,
            models=models,
            template_id=template_id,
            connect_error=connect_error,
            last_connected_at=last_connected_at,
            documentation_url=documentation_url,
            status_url=status_url,
            models_fetched_at=models_fetched_at,
        )

        persona_service.additional_properties = d
        return persona_service

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
