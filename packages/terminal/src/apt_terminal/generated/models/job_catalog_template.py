from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.job_catalog_template_defaults import JobCatalogTemplateDefaults
    from ..models.job_catalog_template_inputs_item import JobCatalogTemplateInputsItem


T = TypeVar("T", bound="JobCatalogTemplate")


@_attrs_define
class JobCatalogTemplate:
    """
    Attributes:
        id (UUID):
        key (str):
        name (str):
        description (None | str):
        version (int): The latest published version.
        inputs (list[JobCatalogTemplateInputsItem]):
        defaults (JobCatalogTemplateDefaults):
        published_at (datetime.datetime):
    """

    id: UUID
    key: str
    name: str
    description: None | str
    version: int
    inputs: list[JobCatalogTemplateInputsItem]
    defaults: JobCatalogTemplateDefaults
    published_at: datetime.datetime
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        key = self.key

        name = self.name

        description: None | str
        description = self.description

        version = self.version

        inputs = []
        for inputs_item_data in self.inputs:
            inputs_item = inputs_item_data.to_dict()
            inputs.append(inputs_item)

        defaults = self.defaults.to_dict()

        published_at = self.published_at.isoformat()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "key": key,
                "name": name,
                "description": description,
                "version": version,
                "inputs": inputs,
                "defaults": defaults,
                "published_at": published_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_catalog_template_defaults import (
            JobCatalogTemplateDefaults,
        )
        from ..models.job_catalog_template_inputs_item import (
            JobCatalogTemplateInputsItem,
        )

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        key = d.pop("key")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        version = d.pop("version")

        inputs = []
        _inputs = d.pop("inputs")
        for inputs_item_data in _inputs:
            inputs_item = JobCatalogTemplateInputsItem.from_dict(inputs_item_data)

            inputs.append(inputs_item)

        defaults = JobCatalogTemplateDefaults.from_dict(d.pop("defaults"))

        published_at = datetime.datetime.fromisoformat(d.pop("published_at"))

        job_catalog_template = cls(
            id=id,
            key=key,
            name=name,
            description=description,
            version=version,
            inputs=inputs,
            defaults=defaults,
            published_at=published_at,
        )

        job_catalog_template.additional_properties = d
        return job_catalog_template

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
